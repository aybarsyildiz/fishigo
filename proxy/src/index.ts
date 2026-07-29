import Anthropic from "@anthropic-ai/sdk";
import { SISTEM_TALIMATI, TUR_IDLERI } from "./tur-listesi";
import kurallar from "../regulations.json";

/**
 * Fishigo recognition proxy (§3/§4 of the brief).
 *
 * - Holds the Anthropic key (Worker secret ANTHROPIC_API_KEY — the client
 *   never sees it).
 * - Enforces the 10-recognitions/month free quota per device via KV.
 *   KV is eventually consistent, so a determined attacker could squeeze a
 *   couple of extra calls in a race — acceptable for a soft free-tier cap;
 *   revisit with Durable Objects if it ever matters.
 * - The LLM answers SPECIES only. Legality never touches this service (§5).
 */

/** Free tier: 10/month (§2.1-11). Pro: a fair-use ceiling that is effectively
 * unlimited for a real angler while bounding cost against a spoofed x-abone
 * header (200 × ~$0.013 ≈ $2.60/mo worst case). Hardening path — verify the
 * StoreKit 2 JWS / App Store Server API — documented in CLAUDE.md. */
const FREE_LIMIT = 10;
const PRO_LIMIT = 200;
function aylikLimit(request: Request): number {
  return request.headers.get("x-abone") === "1" ? PRO_LIMIT : FREE_LIMIT;
}

/** Recognition model. haiku-4-5 ≈ $0.004/tanima; sonnet-4-6 ≈ $0.013/tanima —
 * switched after haiku misread body plans on hard photos (see CLAUDE.md). */
const MODEL = "claude-sonnet-4-6";
/** ~1.4M base64 chars ≈ 1 MB JPEG; client sends ≤1024px @0.7 so far less. */
const MAX_GORSEL_B64 = 2_000_000;

interface TanimaSonucu {
  /** See-first reasoning (§4 accuracy fix): the model must describe the body
   * plan before naming a species. Logged server-side, stripped from the
   * client response. */
  analiz: string;
  tur_id: string | null;
  guven: number;
  alternatifler: string[];
  balik_yok: boolean;
}

const CIKTI_SEMASI = {
  type: "object",
  properties: {
    analiz: { type: "string" },
    tur_id: { anyOf: [{ type: "string" }, { type: "null" }] },
    guven: { type: "number" },
    alternatifler: { type: "array", items: { type: "string" } },
    balik_yok: { type: "boolean" },
  },
  required: ["analiz", "tur_id", "guven", "alternatifler", "balik_yok"],
  additionalProperties: false,
} as const;

export default {
  async fetch(request, env, ctx): Promise<Response> {
    const url = new URL(request.url);
    try {
      if (request.method === "POST" && url.pathname === "/tanima") {
        return await tanima(request, env);
      }
      if (request.method === "POST" && url.pathname === "/coklu") {
        return await coklu(request, env);
      }
      if (request.method === "POST" && url.pathname === "/duzeltme") {
        return await duzeltme(request, env, ctx);
      }
      if (request.method === "GET" && url.pathname === "/kurallar") {
        return kurallarYaniti(request);
      }
      // App Review demo kill-switch (playbook §6, 2.1a). Fail open unless the
      // env var is explicitly "0" so a review can always unlock Pro features.
      if (request.method === "GET" && url.pathname === "/demo") {
        return json({ enabled: (env.DEMO_ACIK as string) !== "0" });
      }
      if (request.method === "GET" && url.pathname === "/gizlilik") {
        return html(GIZLILIK_HTML);
      }
      if (request.method === "GET" && url.pathname === "/kosullar") {
        return html(KOSULLAR_HTML);
      }
      if (request.method === "GET" && url.pathname === "/destek") {
        return html(DESTEK_HTML);
      }
      return json({ hata: "bulunamadi" }, 404);
    } catch (error) {
      console.log(JSON.stringify({ olay: "hata", yol: url.pathname, mesaj: String(error) }));
      return json({ hata: "servis" }, 502);
    }
  },
} satisfies ExportedHandler<Env>;

async function tanima(request: Request, env: Env): Promise<Response> {
  const cihaz = cihazId(request);
  if (!cihaz) return json({ hata: "cihaz" }, 400);

  const govde = await request.json<{ gorsel?: string }>();
  const gorsel = govde.gorsel;
  if (!gorsel || gorsel.length > MAX_GORSEL_B64) return json({ hata: "gorsel" }, 400);

  // Quota check — key rolls over monthly, entries expire on their own.
  const limit = aylikLimit(request);
  const ay = new Date().toISOString().slice(0, 7); // "2026-07"
  const kotaAnahtari = `kota:${cihaz}:${ay}`;
  const kullanilan = parseInt((await env.KOTA.get(kotaAnahtari)) ?? "0", 10);
  if (kullanilan >= limit) {
    return json({ hata: "kota", kalan_hak: 0 }, 429);
  }

  const anthropic = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
  const yanit = await anthropic.messages.create({
    model: MODEL,
    max_tokens: 300,
    // cache_control is inert until the prompt crosses Haiku 4.5's 4096-token
    // cache floor (~1.2k today) — it engages automatically as the list grows.
    system: [
      {
        type: "text",
        text: SISTEM_TALIMATI,
        cache_control: { type: "ephemeral" },
      },
    ],
    output_config: { format: { type: "json_schema", schema: CIKTI_SEMASI } },
    messages: [
      {
        role: "user",
        content: [
          {
            type: "image",
            source: { type: "base64", media_type: "image/jpeg", data: gorsel },
          },
          { type: "text", text: "Identify the fish in this photo." },
        ],
      },
    ],
  });

  const metin = yanit.content.find((b) => b.type === "text");
  if (!metin || metin.type !== "text") return json({ hata: "servis" }, 502);
  const sonuc = JSON.parse(metin.text) as TanimaSonucu;

  // §4 "never invent ids" — server-side backstop against the closed list.
  sonuc.alternatifler = sonuc.alternatifler.filter((id) => TUR_IDLERI.has(id)).slice(0, 2);
  if (sonuc.tur_id !== null && !TUR_IDLERI.has(sonuc.tur_id)) {
    sonuc.tur_id = sonuc.alternatifler[0] ?? null;
    if (sonuc.tur_id === null) sonuc.balik_yok = true;
  }

  await env.KOTA.put(kotaAnahtari, String(kullanilan + 1), {
    expirationTtl: 60 * 60 * 24 * 40,
  });

  console.log(
    JSON.stringify({
      olay: "tanima",
      tur: sonuc.tur_id,
      guven: sonuc.guven,
      analiz: sonuc.analiz,
      girdi_token: yanit.usage.input_tokens,
      cikti_token: yanit.usage.output_tokens,
      onbellek_okuma: yanit.usage.cache_read_input_tokens,
    }),
  );

  // analiz is server-side telemetry — the client contract stays §4-exact.
  const { analiz: _analiz, ...istemciYaniti } = sonuc;
  return json({ ...istemciYaniti, kalan_hak: limit - kullanilan - 1 });
}

/** Bucket mode: identify EVERY fish in one photo (a full catch), so anglers
 * with a bucket don't shoot them one by one. Returns a list; the app lets the
 * user review/edit before bulk-saving. One API call = one quota unit. */
const COKLU_SEMASI = {
  type: "object",
  properties: {
    analiz: { type: "string" },
    baliklar: {
      type: "array",
      items: {
        type: "object",
        properties: {
          tur_id: { anyOf: [{ type: "string" }, { type: "null" }] },
          guven: { type: "number" },
        },
        required: ["tur_id", "guven"],
        additionalProperties: false,
      },
    },
    balik_yok: { type: "boolean" },
  },
  required: ["analiz", "baliklar", "balik_yok"],
  additionalProperties: false,
} as const;

interface CokluSonuc {
  analiz: string;
  baliklar: { tur_id: string | null; guven: number }[];
  balik_yok: boolean;
}

async function coklu(request: Request, env: Env): Promise<Response> {
  const cihaz = cihazId(request);
  if (!cihaz) return json({ hata: "cihaz" }, 400);

  const govde = await request.json<{ gorsel?: string }>();
  const gorsel = govde.gorsel;
  if (!gorsel || gorsel.length > MAX_GORSEL_B64) return json({ hata: "gorsel" }, 400);

  const limit = aylikLimit(request);
  const ay = new Date().toISOString().slice(0, 7);
  const kotaAnahtari = `kota:${cihaz}:${ay}`;
  const kullanilan = parseInt((await env.KOTA.get(kotaAnahtari)) ?? "0", 10);
  if (kullanilan >= limit) return json({ hata: "kota", kalan_hak: 0 }, 429);

  const anthropic = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });
  const yanit = await anthropic.messages.create({
    model: MODEL,
    max_tokens: 700,
    system: [{ type: "text", text: SISTEM_TALIMATI, cache_control: { type: "ephemeral" } }],
    output_config: { format: { type: "json_schema", schema: COKLU_SEMASI } },
    messages: [
      {
        role: "user",
        content: [
          { type: "image", source: { type: "base64", media_type: "image/jpeg", data: gorsel } },
          {
            type: "text",
            text: "This photo shows a recreational angler's CATCH — likely several fish together (a bucket, a stringer, laid on the ground). Identify EVERY distinct fish you can see, one entry per fish, up to 20. Follow the same see-first, body-plan, confidence rules. If they are all the same species, still list one entry per individual.",
          },
        ],
      },
    ],
  });

  const metin = yanit.content.find((b) => b.type === "text");
  if (!metin || metin.type !== "text") return json({ hata: "servis" }, 502);
  const sonuc = JSON.parse(metin.text) as CokluSonuc;

  const temiz = sonuc.baliklar
    .filter((b) => b.tur_id !== null && TUR_IDLERI.has(b.tur_id))
    .slice(0, 20);

  console.log(
    JSON.stringify({
      olay: "coklu",
      adet: temiz.length,
      analiz: sonuc.analiz,
      girdi_token: yanit.usage.input_tokens,
      cikti_token: yanit.usage.output_tokens,
    }),
  );

  await env.KOTA.put(kotaAnahtari, String(kullanilan + 1), { expirationTtl: 60 * 60 * 24 * 40 });
  return json({ baliklar: temiz, balik_yok: sonuc.balik_yok, kalan_hak: limit - kullanilan - 1 });
}

/** Correction log (§4): photo hash + suggested vs corrected id — the future
 * accuracy dataset. Fire-and-forget from the client's perspective. */
async function duzeltme(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
  const cihaz = cihazId(request);
  if (!cihaz) return json({ hata: "cihaz" }, 400);

  const govde = await request.json<{
    foto_ozet?: string;
    onerilen?: string;
    duzeltilen?: string;
  }>();
  if (!govde.foto_ozet || !govde.duzeltilen) return json({ hata: "govde" }, 400);

  ctx.waitUntil(
    env.KOTA.put(
      `duzeltme:${Date.now()}:${crypto.randomUUID()}`,
      JSON.stringify({
        cihaz,
        foto_ozet: govde.foto_ozet,
        onerilen: govde.onerilen ?? null,
        duzeltilen: govde.duzeltilen,
        zaman: new Date().toISOString(),
      }),
    ),
  );
  return json({ tamam: true });
}

/** §5: regulations as static JSON, ETag-cached — rule updates ship with a
 * Worker deploy, never an App Store release. The LLM never touches this. */
function kurallarYaniti(request: Request): Response {
  const etag = `"${(kurallar as { version: string }).version}"`;
  if (request.headers.get("if-none-match") === etag) {
    return new Response(null, { status: 304, headers: { etag } });
  }
  return new Response(JSON.stringify(kurallar), {
    headers: {
      "content-type": "application/json",
      etag,
      "cache-control": "max-age=3600",
    },
  });
}

function cihazId(request: Request): string | null {
  const id = request.headers.get("x-cihaz");
  if (!id || id.length < 8 || id.length > 64) return null;
  return id;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

function html(body: string): Response {
  return new Response(body, {
    headers: { "content-type": "text/html; charset=utf-8", "cache-control": "max-age=3600" },
  });
}

// Apple requires functional Privacy Policy + Terms links on the paywall
// (Guideline 3.1.2). Hosting them here keeps the links real. DRAFT — the owner
// should have these reviewed and swap in a real support email before launch.
const SAYFA = (baslik: string, govde: string) => `<!doctype html><html lang="tr"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${baslik} · Fishigo</title>
<style>body{font-family:-apple-system,system-ui,sans-serif;max-width:680px;margin:0 auto;padding:32px 20px;color:#16303D;background:#EDE5D1;line-height:1.6}h1{font-weight:800}h2{margin-top:28px;font-size:1.1rem}a{color:#C2402F}small{color:#28414E}</style>
</head><body>${govde}<hr><small>Fishigo · Son güncelleme 2026-07 · Taslak, resmî yayından önce hukuki incelemeden geçirilecektir.</small></body></html>`;

const GIZLILIK_HTML = SAYFA("Gizlilik Politikası", `
<h1>Gizlilik Politikası</h1>
<p>Fishigo, gizliliği ürünün merkezine koyar. "Noktan sende kalır."</p>
<h2>Cihazında kalan veriler</h2>
<p>Yakalayışların, fotoğrafların, konumların ve notların cihazında saklanır. İstersen Apple'ın iCloud özel veritabanı ile yalnızca senin erişebileceğin şekilde eşitlenir. Bu verileri biz görmeyiz.</p>
<h2>Tür tanıma</h2>
<p>Tanıma için fotoğrafın, işlenmek üzere tanıma servisimize (Anthropic API üzerinden çalışan aracımıza) geçici olarak gönderilir. Tanıma sonrası fotoğraf saklanmaz. Yalnızca sen bir teşhisi düzeltirsen, fotoğrafın <em>özeti</em> (geri döndürülemez bir hash) ve tür bilgisi doğruluk verisi olarak tutulabilir; fotoğrafın kendisi gönderilmez.</p>
<h2>Konum</h2>
<p>Konum yalnızca kendi özel haritan, hava durumu ve il bilgisi için kullanılır. Paylaşım kartlarında yalnızca <strong>il</strong> görünür; koordinat veya nokta asla paylaşılmaz veya herkese açık hale getirilmez.</p>
<h2>Anonim kimlik</h2>
<p>Aylık ücretsiz tanıma hakkını saymak için cihazına anonim bir kimlik atanır. Kişisel bilgilerinle ilişkilendirilmez.</p>
<h2>Abonelik</h2>
<p>Fishigo Pro ödemeleri Apple üzerinden yapılır; ödeme bilgilerini biz görmeyiz veya saklamayız.</p>
<h2>Üçüncü taraf takip / reklam</h2>
<p>Fishigo üçüncü taraf reklam veya takip teknolojisi kullanmaz.</p>
<h2>Dış kaynaklar</h2>
<p>Hava durumu Open-Meteo'dan, tür bölge verisi GBIF ve OBIS açık verisinden alınır.</p>
<h2>İletişim</h2>
<p>Sorular için: <a href="mailto:aybars@netnucleus.solutions">aybars@netnucleus.solutions</a>.</p>`);

const KOSULLAR_HTML = SAYFA("Kullanım Koşulları", `
<h1>Kullanım Koşulları</h1>
<p>Fishigo'yu kullanarak bu koşulları kabul edersin.</p>
<h2>Bilgilendirme amaçlıdır</h2>
<p>Uygulamadaki tür teşhisi, boy/sezon yasağı ve koşul puanı <strong>bilgilendirme amaçlıdır ve bağlayıcı değildir</strong>. Avlanma kurallarında bağlayıcı kaynak Resmî Gazete ve Tarım ve Orman Bakanlığı amatör balıkçılık tebliğidir. Koşul puanı bir balık vaadi değildir. Yasal ve güvenli avlanmaktan kullanıcı sorumludur.</p>
<h2>Abonelik (Fishigo Pro)</h2>
<p>Fishigo Pro, aylık veya yıllık otomatik yenilenen bir aboneliktir. Ödeme, satın alma onayında Apple Kimliğine işlenir. Abonelik, dönem bitiminden en az 24 saat önce kapatılmadıkça otomatik yenilenir ve yenileme ücreti dönem bitiminden önceki 24 saat içinde alınır. Abonelikleri satın aldıktan sonra cihazının Ayarlar &gt; Apple Kimliği &gt; Abonelikler bölümünden yönetebilir veya iptal edebilirsin.</p>
<h2>Standart lisans</h2>
<p>Aksi belirtilmedikçe Apple'ın standart Son Kullanıcı Lisans Sözleşmesi (EULA) geçerlidir: <a href="https://www.apple.com/legal/internet-services/itunes/dev/stdeula/">apple.com/legal/…/stdeula</a></p>
<h2>İletişim</h2>
<p><a href="mailto:aybars@netnucleus.solutions">aybars@netnucleus.solutions</a>.</p>`);

const DESTEK_HTML = SAYFA("Destek", `
<h1>Fishigo Destek</h1>
<p>Bir sorun, öneri veya soru için bize ulaş. Genellikle birkaç iş günü içinde yanıt veriyoruz.</p>
<h2>İletişim</h2>
<p>E-posta: <a href="mailto:aybars@netnucleus.solutions">aybars@netnucleus.solutions</a></p>
<h2>Sık sorulanlar</h2>
<p><strong>Tür yanlış tanındı, ne yapmalıyım?</strong><br>Onay ekranında "Değiştir" ile doğru türü seç; bu düzeltmeler tanımayı zamanla iyileştirir.</p>
<p><strong>Boy limiti / sezon bilgisi bağlayıcı mı?</strong><br>Hayır, bilgilendirme amaçlıdır. Bağlayıcı kaynak Resmî Gazete ve Tarım ve Orman Bakanlığı amatör balıkçılık tebliğidir.</p>
<p><strong>Konumum paylaşılıyor mu?</strong><br>Hayır. Yakaladığın noktalar yalnızca kendi haritanda görünür. Paylaşım kartlarında yalnızca il görünür. Noktan sende kalır.</p>
<p><strong>Aboneliğimi nasıl yönetirim?</strong><br>iPhone Ayarlar &gt; Apple Kimliği &gt; Abonelikler bölümünden yönetebilir veya iptal edebilirsin.</p>`);
