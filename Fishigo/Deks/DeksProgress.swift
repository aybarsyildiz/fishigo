import Foundation

/// Pure deks/evolution-line math over the record set. Kept free of stores so
/// the same rules serve the grid, the detail sheet, the hook module, and the
/// post-save celebration.
enum DeksProgress {
    static func caughtIds(_ records: [CatchRecord]) -> Set<String> {
        Set(records.map(\.speciesId))
    }

    /// Which size-name band a length falls into (index into `boyAdlari`).
    static func bandIndex(of species: Species, lengthCm: Int) -> Int {
        for (index, band) in species.boyAdlari.enumerated() {
            if let max = band.maxCm, lengthCm <= max { return index }
        }
        return species.boyAdlari.count - 1
    }

    /// Bands of the evolution line already achieved with logged catches.
    static func bandsCaught(_ species: Species, records: [CatchRecord]) -> Set<Int> {
        Set(records
            .filter { $0.speciesId == species.id }
            .map { bandIndex(of: species, lengthCm: $0.lengthCm) })
    }

    static func isLineComplete(_ species: Species, records: [CatchRecord]) -> Bool {
        species.hasEvolutionLine
            && bandsCaught(species, records: records).count == species.boyAdlari.count
    }
}
