import Foundation

/// License and byte provenance travel with the offline photo bank so TV credits
/// remain available without a network connection. Each photo retains its own license.
struct AnimalPhotoAttribution: Equatable {
    let author: String
    let creditLine: String
    let licenseName: String
    let licenseURL: String
    let sourceURL: String
    let originalURL: String
    let downloadedURL: String
    let originalSHA256: String?
    let downloadedSHA256: String
    let derivativeSHA256: String
    let derivativeWidth: Int
    let derivativeHeight: Int
    let modificationDescription: String
    let grantNote: String
}

struct AnimalExplorerEntry: Identifiable, Equatable {
    let card: MemoryAnimal
    let speciesID: String
    let collectionIDs: [String]
    let neutralPhotoDescription: String
    let hint: String?
    let photoCredit: String?
    let photoAttribution: AnimalPhotoAttribution?
    var id: String { card.id }
}

struct AnimalExplorerCollection: Identifiable, Equatable {
    let id: String
    let title: String
    let spokenDescription: String
}

enum AnimalExplorerCatalog {
    static let contentVersion = 1

    static let collections: [AnimalExplorerCollection] = [
        .init(id: "all-animals", title: "All animals", spokenDescription: "Explore all of the animal photographs."),
        .init(id: "india-wildlife", title: "Wildlife of India", spokenDescription: "These species are found in India. Some photographs were taken in other places or in zoos."),
        .init(id: "birds", title: "Birds", spokenDescription: "Look closely at feathers, beaks and wings."),
        .init(id: "reptiles", title: "Reptiles", spokenDescription: "Look closely at the scales and shapes of these reptiles."),
        .init(id: "farm-animals", title: "Farm animals", spokenDescription: "Meet animals people keep on farms. A photograph may come from another country."),
        .init(id: "little-neighbors", title: "Little neighbors", spokenDescription: "Meet smaller animals that can be found around Indian towns and countryside.")
    ]

    /// Supply a frozen card snapshot. Exact known identities get their photo
    /// metadata; unknown incoming cards preserve their authored facts and pictures.
    static func entries(for cards: [MemoryAnimal]) -> [AnimalExplorerEntry] {
        cards.map { card in
            if let reviewed = photoEntries.first(where: { $0.card == card }) {
                return reviewed
            }
            return AnimalExplorerEntry(
                card: card, speciesID: card.id, collectionIDs: ["all-animals"],
                neutralPhotoDescription: "Animal picture.", hint: nil,
                photoCredit: nil, photoAttribution: nil
            )
        }
    }

    static let photoEntries: [AnimalExplorerEntry] = [
        entry(
            id: "bengal-tiger", name: "Bengal tiger", scientificName: "Panthera tigris tigris",
            group: "Mammal", asset: "AnimalPhotoBengalTiger", collections: ["all-animals", "india-wildlife"],
            description: "A striped animal resting on rocks.", hint: "Look at the dark stripes on its orange coat.",
            attribution: AnimalPhotoAttribution(
                author: "Nidhi.pious996", creditLine: "Nidhi.pious996",
                licenseName: "CC BY-SA 4.0 International", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:The_Bengal_tiger.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/8/8e/The_Bengal_tiger.jpg",
                downloadedURL: "https://upload.wikimedia.org/wikipedia/commons/8/8e/The_Bengal_tiger.jpg",
                originalSHA256: "229c169140b2c8944b5d2dce8b770cfb044f2d865086bad18881970a3f539d78",
                downloadedSHA256: "229c169140b2c8944b5d2dce8b770cfb044f2d865086bad18881970a3f539d78",
                derivativeSHA256: "58eeedd6ab4b3e61b979865f86070cfd9988e7191fd1bb08fe4d6bfe022256f5",
                derivativeWidth: 1600, derivativeHeight: 1059,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "asiatic-lion", name: "Asiatic lion", scientificName: "Panthera leo",
            group: "Mammal", asset: "AnimalPhotoAsiaticLion", collections: ["all-animals", "india-wildlife"],
            description: "An animal with a shaggy mane resting among dry leaves.", hint: "Look at the mane around its face.",
            attribution: AnimalPhotoAttribution(
                author: "Asim Patel", creditLine: "Asim Patel",
                licenseName: "CC BY-SA 3.0 Unported", licenseURL: "https://creativecommons.org/licenses/by-sa/3.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:AsiaticLionMale.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/7/76/AsiaticLionMale.jpg",
                downloadedURL: "https://upload.wikimedia.org/wikipedia/commons/7/76/AsiaticLionMale.jpg",
                originalSHA256: "e556e04add9577e20dda7574d60ff71600c098618db7484cd347e71a74f1c0b3",
                downloadedSHA256: "e556e04add9577e20dda7574d60ff71600c098618db7484cd347e71a74f1c0b3",
                derivativeSHA256: "4f7053b2f2d70dcebd7c791a8c707970ef38e8449dc43b0561f04a5de419933d",
                derivativeWidth: 1600, derivativeHeight: 1067,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "indian-leopard", name: "Indian leopard", scientificName: "Panthera pardus fusca",
            group: "Mammal", asset: "AnimalPhotoIndianLeopard", collections: ["all-animals", "india-wildlife"],
            description: "A spotted animal walking through dry grass.", hint: "Look at the dark spots across its coat.",
            attribution: AnimalPhotoAttribution(
                author: "Thomas Fuhrmann", creditLine: "Thomas Fuhrmann, snowman@snowmanstudios.de",
                licenseName: "CC BY-SA 4.0 International", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Indian_Leopard_(Panthera_pardus_ssp._fusca),_Ranthambore_National_Park.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/b/bb/Indian_Leopard_(Panthera_pardus_ssp._fusca)%2C_Ranthambore_National_Park.jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/b/bb/Indian_Leopard_(Panthera_pardus_ssp._fusca)%2C_Ranthambore_National_Park.jpg/1280px-Indian_Leopard_%28Panthera_pardus_ssp._fusca%29%2C_Ranthambore_National_Park.jpg",
                originalSHA256: nil,
                downloadedSHA256: "6c508a7d11848100557c4b2dfbc8aacdee74bbd5fe5405aa60def6833b5ae89f",
                derivativeSHA256: "c77f687a52c82f17434c6c446225282b95049a9c075b5792acdf3b311322ebef",
                derivativeWidth: 1280, derivativeHeight: 853,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "asian-elephant", name: "Asian elephant", scientificName: "Elephas maximus",
            group: "Mammal", asset: "AnimalPhotoAsianElephant", collections: ["all-animals", "india-wildlife"],
            description: "A large animal facing the camera, with a long trunk and two tusks.", hint: "Look at its long trunk.",
            attribution: AnimalPhotoAttribution(
                author: "Sukanta.daswiki", creditLine: "Sukanta.daswiki",
                licenseName: "CC BY-SA 4.0 International", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Asiatic_Elephant_Kabini.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/4/44/Asiatic_Elephant_Kabini.jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/4/44/Asiatic_Elephant_Kabini.jpg/1280px-Asiatic_Elephant_Kabini.jpg",
                originalSHA256: nil,
                downloadedSHA256: "c3c9886e091fbf0c97f90061c0314567d07e5fc73c8a87fd452e2aeb48178523",
                derivativeSHA256: "5cd804d9d799f8c10bb9b6863df9b0deb20bd51230b5d80316e6eab27c2bf0bf",
                derivativeWidth: 1280, derivativeHeight: 1163,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "indian-rhinoceros", name: "Indian rhinoceros", scientificName: "Rhinoceros unicornis",
            group: "Mammal", asset: "AnimalPhotoIndianRhinoceros", collections: ["all-animals", "india-wildlife"],
            description: "A large grey animal with folded skin and one horn, standing on a path.", hint: "Look at the single horn above its nose.",
            attribution: AnimalPhotoAttribution(
                author: "Joydeep Chakraborty", creditLine: "Photo: Joydeep Chakraborty / Wikimedia Commons / CC BY-SA 4.0",
                licenseName: "CC BY-SA 4.0 International", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:An_Indian_rhinoceros_(Rhinoceros_unicornis),_also_known_as_the_greater_one-horned_rhinoceros,_at_Kaziranga_National_Park,_Assam,_India_2.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/c/c4/An_Indian_rhinoceros_(Rhinoceros_unicornis)%2C_also_known_as_the_greater_one-horned_rhinoceros%2C_at_Kaziranga_National_Park%2C_Assam%2C_India_2.jpg",
                downloadedURL: "https://upload.wikimedia.org/wikipedia/commons/c/c4/An_Indian_rhinoceros_(Rhinoceros_unicornis)%2C_also_known_as_the_greater_one-horned_rhinoceros%2C_at_Kaziranga_National_Park%2C_Assam%2C_India_2.jpg",
                originalSHA256: "9e61c93712d53cd4864ee933f84935a59773664c1b9f986365d0fc3826bced11",
                downloadedSHA256: "9e61c93712d53cd4864ee933f84935a59773664c1b9f986365d0fc3826bced11",
                derivativeSHA256: "d39bd6b520f4b7c3944edd0db9e4664ea1009a44f7f647ccb6445e52beadbcc2",
                derivativeWidth: 1600, derivativeHeight: 972,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "sloth-bear", name: "Sloth bear", scientificName: "Melursus ursinus",
            group: "Mammal", asset: "AnimalPhotoSlothBear", collections: ["all-animals", "india-wildlife"],
            description: "A shaggy dark animal walking with its nose close to the ground.", hint: "Look at its long dark fur and pale muzzle.",
            attribution: AnimalPhotoAttribution(
                author: "Mike Prince", creditLine: "© Mike Prince",
                licenseName: "CC BY 2.0 Generic", licenseURL: "https://creativecommons.org/licenses/by/2.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Sloth_bear_(Melursus_ursinus)_is_a_terrestrial_mammal_in_Pilibhit_tiger_reserve.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/d/d6/Sloth_bear_(Melursus_ursinus)_is_a_terrestrial_mammal_in_Pilibhit_tiger_reserve.jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d6/Sloth_bear_(Melursus_ursinus)_is_a_terrestrial_mammal_in_Pilibhit_tiger_reserve.jpg/1280px-Sloth_bear_%28Melursus_ursinus%29_is_a_terrestrial_mammal_in_Pilibhit_tiger_reserve.jpg",
                originalSHA256: nil,
                downloadedSHA256: "250dc84aa46b4c959c2e9fc48bb2a3823673d4a997558fec78b91884e7628cba",
                derivativeSHA256: "e43cb5fb4943562a2cc5c44dea4264354085d2246ee1f9a1af40d07c57bb2dce",
                derivativeWidth: 1280, derivativeHeight: 853,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Commons explicitly grants CC BY 2.0 and records Flickr review by FlickreviewR 2 on 2025-10-27 confirming that license. Stale EXIF All rights reserved is retained in the source but is not the grant relied upon."
            )
        ),
        entry(
            id: "blackbuck", name: "Blackbuck", scientificName: "Antilope cervicapra",
            group: "Mammal", asset: "AnimalPhotoBlackbuck", collections: ["all-animals", "india-wildlife"],
            description: "An animal with slender legs and spiral horns, standing in grass.", hint: "Look at the two spiral horns.",
            attribution: AnimalPhotoAttribution(
                author: "N. A. Naseer", creditLine: "N. A. Naseer / www.nilgirimarten.com / naseerart@gmail.com",
                licenseName: "CC BY-SA 2.5 India", licenseURL: "https://creativecommons.org/licenses/by-sa/2.5/in/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Blackbuck_by_N_A_Nazeer.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/b/bd/Blackbuck_by_N_A_Nazeer.jpg",
                downloadedURL: "https://upload.wikimedia.org/wikipedia/commons/b/bd/Blackbuck_by_N_A_Nazeer.jpg",
                originalSHA256: "89b7f48c400053dfc6ed564f097b3dab834a4c2ade51c9e910f6911ca954f62a",
                downloadedSHA256: "89b7f48c400053dfc6ed564f097b3dab834a4c2ade51c9e910f6911ca954f62a",
                derivativeSHA256: "de065b4a76809e372f6c0962f709869fa108092f662e5cd9f78ced7c4db104cd",
                derivativeWidth: 1600, derivativeHeight: 1288,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Commons records the explicit CC BY-SA 2.5 India grant and full required Naseer attribution, with Wikimedia VRT permission ticket 2013082110009341. Stale EXIF for blackbuck is not the grant relied upon."
            )
        ),
        entry(
            id: "chital", name: "Chital (spotted deer)", scientificName: "Axis axis",
            group: "Mammal", asset: "AnimalPhotoChital", collections: ["all-animals", "india-wildlife"],
            description: "An animal with white spots and branching antlers, standing in grass.", hint: "Look at the white spots on its brown coat.",
            attribution: AnimalPhotoAttribution(
                author: "T. R. Shankar Raman", creditLine: "T. R. Shankar Raman",
                licenseName: "CC BY-SA 4.0 International", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:A_chital_stag_1.JPG",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/a/a7/A_chital_stag_1.JPG",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a7/A_chital_stag_1.JPG/1280px-A_chital_stag_1.JPG",
                originalSHA256: nil,
                downloadedSHA256: "f6f0e3f6df060269e48cfe603d6614625a9dd5284ab800c70db0eb9d6bb3805f",
                derivativeSHA256: "215184025f203b8c244823a1d35ad91a26f5f53585afca49296169f931317d05",
                derivativeWidth: 1280, derivativeHeight: 850,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "indian-peafowl", name: "Indian peafowl (peacock)", scientificName: "Pavo cristatus",
            group: "Bird", asset: "AnimalPhotoIndianPeafowl", collections: ["all-animals", "india-wildlife", "birds"],
            description: "A blue-necked bird with a large fan of patterned feathers.", hint: "Look at the wide fan of feathers.",
            attribution: AnimalPhotoAttribution(
                author: "N. A. Naseer", creditLine: "N. A. Naseer / www.nilgirimarten.com / naseerart@gmail.com",
                licenseName: "CC BY-SA 2.5 India", licenseURL: "https://creativecommons.org/licenses/by-sa/2.5/in/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Peacock_in_display_by_N_A_Nazeer.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/a/a0/Peacock_in_display_by_N_A_Nazeer.jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a0/Peacock_in_display_by_N_A_Nazeer.jpg/1280px-Peacock_in_display_by_N_A_Nazeer.jpg",
                originalSHA256: nil,
                downloadedSHA256: "815d220d5a7d1bf1e8593d2d70595b42490af9edc592787f6f60ffb7a2174609",
                derivativeSHA256: "98b57ad40ed01f0240bd55ca0961c5bd0ffeb43a5c8af6149ad6c9f0302cd497",
                derivativeWidth: 1280, derivativeHeight: 994,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Commons records the explicit CC BY-SA 2.5 India grant for this peafowl photograph and full required Naseer attribution, with Wikimedia VRT permission ticket 2013082110009341."
            )
        ),
        entry(
            id: "rose-ringed-parakeet", name: "Rose-ringed parakeet", scientificName: "Psittacula krameri",
            group: "Bird", asset: "AnimalPhotoRoseRingedParakeet", collections: ["all-animals", "india-wildlife", "birds"],
            description: "Two green birds with red beaks perched on a tree.", hint: "Look at their red curved beaks and long tails.",
            attribution: AnimalPhotoAttribution(
                author: "Tisha Mukherjee", creditLine: "Tisha Mukherjee",
                licenseName: "CC BY-SA 4.0 International", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Rose-ringed_parakeet_11.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/b/b6/Rose-ringed_parakeet_11.jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b6/Rose-ringed_parakeet_11.jpg/1280px-Rose-ringed_parakeet_11.jpg",
                originalSHA256: nil,
                downloadedSHA256: "029b00c8c7346145f2758f8ac59f65c2d2234a8add7561819ab7dcc16a62424f",
                derivativeSHA256: "1f3ee0d2faa9bfae870732e288f9c00ea44be0e6984690475f8bb73efadbe33b",
                derivativeWidth: 1280, derivativeHeight: 853,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "indian-roller", name: "Indian roller", scientificName: "Coracias benghalensis",
            group: "Bird", asset: "AnimalPhotoIndianRoller", collections: ["all-animals", "india-wildlife", "birds"],
            description: "A bird with blue wings and a brownish breast perched on a branch.", hint: "Look at the blue feathers along its wings and tail.",
            attribution: AnimalPhotoAttribution(
                author: "Charles J. Sharp", creditLine: "Charles J. Sharp",
                licenseName: "CC BY-SA 4.0 International", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Indian_roller_(Coracias_benghalensis_benghalensis).jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/8/8c/Indian_roller_(Coracias_benghalensis_benghalensis).jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8c/Indian_roller_(Coracias_benghalensis_benghalensis).jpg/1280px-Indian_roller_%28Coracias_benghalensis_benghalensis%29.jpg",
                originalSHA256: nil,
                downloadedSHA256: "494d21a4c3bcbf59fd10489198b07b3bb34c0d4647039b6f779ce0a02ffba41a",
                derivativeSHA256: "59e391aff674fb860b0854a42a99f0543d73e9f81f87a46fbee318d0b364f3f5",
                derivativeWidth: 1280, derivativeHeight: 853,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "common-kingfisher", name: "Common kingfisher", scientificName: "Alcedo atthis",
            group: "Bird", asset: "AnimalPhotoCommonKingfisher", collections: ["all-animals", "india-wildlife", "birds"],
            description: "A blue and orange bird with a long straight beak perched on a branch.", hint: "Look at the long pointed beak.",
            attribution: AnimalPhotoAttribution(
                author: "Charles J. Sharp", creditLine: "Charles J. Sharp",
                licenseName: "CC BY-SA 4.0 International", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Common_kingfisher_(Alecedo_atthis_bengalensis)_male_Udaipur.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/2/26/Common_kingfisher_(Alecedo_atthis_bengalensis)_male_Udaipur.jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/2/26/Common_kingfisher_(Alecedo_atthis_bengalensis)_male_Udaipur.jpg/1280px-Common_kingfisher_%28Alecedo_atthis_bengalensis%29_male_Udaipur.jpg",
                originalSHA256: nil,
                downloadedSHA256: "eaa46e4a51af1bf0faf451d308a71e44d88ce9cc8814d9c297b7ba788aeaf63f",
                derivativeSHA256: "14c761783c6f3ba3bdd492c657805f1174690effc92d39c61e37ee936770e1dc",
                derivativeWidth: 1280, derivativeHeight: 1280,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "great-hornbill", name: "Great hornbill", scientificName: "Buceros bicornis",
            group: "Bird", asset: "AnimalPhotoGreatHornbill", collections: ["all-animals", "india-wildlife", "birds"],
            description: "A black and yellow bird with a large curved beak perched high in a tree.", hint: "Look at the raised yellow shape above its beak.",
            attribution: AnimalPhotoAttribution(
                author: "Mike Prince", creditLine: "© Mike Prince",
                licenseName: "CC BY 2.0 Generic", licenseURL: "https://creativecommons.org/licenses/by/2.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Great_Hornbill_(50900986492).jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/b/b3/Great_Hornbill_(50900986492).jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/b/b3/Great_Hornbill_(50900986492).jpg/1280px-Great_Hornbill_%2850900986492%29.jpg",
                originalSHA256: nil,
                downloadedSHA256: "06435c878c6a9e8d944eb6af8cc694768355b67b343f5d6433a29d6c3840589e",
                derivativeSHA256: "6eabfcc2fbc3399f42a5ad2b3f1dd141b34740ff607552d92bfd28aee09f7973",
                derivativeWidth: 1280, derivativeHeight: 853,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "sarus-crane", name: "Sarus crane", scientificName: "Antigone antigone",
            group: "Bird", asset: "AnimalPhotoSarusCrane", collections: ["all-animals", "india-wildlife", "birds"],
            description: "A tall grey bird with a red head and long legs standing in grass.", hint: "Look at its long legs and red head.",
            attribution: AnimalPhotoAttribution(
                author: "Charles J. Sharp", creditLine: "Charles J. Sharp",
                licenseName: "CC BY-SA 4.0 International", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Sarus_crane_(Grus_antigone).jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/8/8c/Sarus_crane_(Grus_antigone).jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8c/Sarus_crane_(Grus_antigone).jpg/1280px-Sarus_crane_%28Grus_antigone%29.jpg",
                originalSHA256: nil,
                downloadedSHA256: "2f4a3fa182158fabbe5d9ec8f2589e5c76819a58bcef02455aabd8c902737526",
                derivativeSHA256: "6165b7611a3b7fa18a5ac1fc6f876d6b808d47965875dc2933164e5da3174055",
                derivativeWidth: 1066, derivativeHeight: 1600,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "spotted-owlet", name: "Spotted owlet", scientificName: "Athene brama",
            group: "Bird", asset: "AnimalPhotoSpottedOwlet", collections: ["all-animals", "india-wildlife", "birds"],
            description: "A small spotted bird with round yellow eyes perched on a branch.", hint: "Look at its two round yellow eyes.",
            attribution: AnimalPhotoAttribution(
                author: "Giles Laurent", creditLine: "© Giles Laurent, gileslaurent.com, License CC BY-SA",
                licenseName: "CC BY-SA 4.0 International", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:044_Spotted_owlet_in_Keoladeo_National_Park_Photo_by_Giles_Laurent.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/0/0f/044_Spotted_owlet_in_Keoladeo_National_Park_Photo_by_Giles_Laurent.jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0f/044_Spotted_owlet_in_Keoladeo_National_Park_Photo_by_Giles_Laurent.jpg/1280px-044_Spotted_owlet_in_Keoladeo_National_Park_Photo_by_Giles_Laurent.jpg",
                originalSHA256: nil,
                downloadedSHA256: "a8d1156b9c7ab8499b6c4ed4682a0ed9fee76a0bd66d032b1695e2947f64bd30",
                derivativeSHA256: "2bef5caf5713a29803d6637ef0bd81f8c81850dbb539106ff0dc34b7cdae40aa",
                derivativeWidth: 1280, derivativeHeight: 853,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "house-crow", name: "House crow", scientificName: "Corvus splendens",
            group: "Bird", asset: "AnimalPhotoHouseCrow", collections: ["all-animals", "india-wildlife", "birds", "little-neighbors"],
            description: "A dark bird with a grey neck walking along a wall.", hint: "Look at its grey neck and dark beak.",
            attribution: AnimalPhotoAttribution(
                author: "Shanmugamp7", creditLine: "Shanmugamp7",
                licenseName: "CC BY-SA 3.0 Unported", licenseURL: "https://creativecommons.org/licenses/by-sa/3.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:House_crow_-_Corvus_splendens.JPG",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/a/af/House_crow_-_Corvus_splendens.JPG",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/a/af/House_crow_-_Corvus_splendens.JPG/1280px-House_crow_-_Corvus_splendens.JPG",
                originalSHA256: nil,
                downloadedSHA256: "2ea4056424db70f2640ca6814df1414c9b3fdd4b2e61d34890d8da1549abe922",
                derivativeSHA256: "bbb62ab75e3319bae05f5c0b15c4867fa9c9c95d4ec3ecbb80f8358d2ab29f21",
                derivativeWidth: 1280, derivativeHeight: 853,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "gharial", name: "Gharial", scientificName: "Gavialis gangeticus",
            group: "Reptile", asset: "AnimalPhotoGharial", collections: ["all-animals", "india-wildlife", "reptiles"],
            description: "A long scaly animal in shallow water with a very narrow snout.", hint: "Look at its long narrow snout.",
            attribution: AnimalPhotoAttribution(
                author: "Charles J. Sharp", creditLine: "Charles J. Sharp",
                licenseName: "CC BY-SA 4.0 International", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Gharial_(Gavialis_gangeticus)_male.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/a/a7/Gharial_(Gavialis_gangeticus)_male.jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a7/Gharial_(Gavialis_gangeticus)_male.jpg/1280px-Gharial_%28Gavialis_gangeticus%29_male.jpg",
                originalSHA256: nil,
                downloadedSHA256: "ceb3fe5cad2c44eafb63e33c988553d4455c207ea8a0480d13283b11964a1cdb",
                derivativeSHA256: "011ddf2f995531e19f0f3f81044a7d44e67389a8684b9253d1dc4245b3c1ba0c",
                derivativeWidth: 1280, derivativeHeight: 853,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "mugger-crocodile", name: "Mugger crocodile", scientificName: "Crocodylus palustris",
            group: "Reptile", asset: "AnimalPhotoMuggerCrocodile", collections: ["all-animals", "india-wildlife", "reptiles"],
            description: "A scaly animal resting on the ground with a broad snout.", hint: "Look at its broad snout and bumpy back.",
            attribution: AnimalPhotoAttribution(
                author: "jackol (Mikhail Esteves)", creditLine: "jackol (Mikhail Esteves)",
                licenseName: "CC BY 2.0 Generic", licenseURL: "https://creativecommons.org/licenses/by/2.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Large_mugger_crocodile.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/d/d7/Large_mugger_crocodile.jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d7/Large_mugger_crocodile.jpg/1280px-Large_mugger_crocodile.jpg",
                originalSHA256: nil,
                downloadedSHA256: "b2c9699ea1321c66dfa4e5047a65f88df30317b9aecab1b16f355be90082f15a",
                derivativeSHA256: "02d39f5877c53cbc6af12da58cf0671eb3a7d4faf64128966084452a226e8276",
                derivativeWidth: 1280, derivativeHeight: 960,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "indian-cobra", name: "Indian cobra", scientificName: "Naja naja",
            group: "Reptile", asset: "AnimalPhotoIndianCobra", collections: ["all-animals", "india-wildlife", "reptiles"],
            description: "A coiled animal with a raised, wide hood behind its head.", hint: "Look at the wide hood behind its raised head.",
            attribution: AnimalPhotoAttribution(
                author: "Pavan Kumar N (Simplypavi); crop uploaded by JMK", creditLine: "Pavan Kumar N (Simplypavi); crop uploaded by JMK",
                licenseName: "CC BY-SA 3.0 Unported", licenseURL: "https://creativecommons.org/licenses/by-sa/3.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Indian_Cobra,_crop.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/8/84/Indian_Cobra%2C_crop.jpg",
                downloadedURL: "https://upload.wikimedia.org/wikipedia/commons/8/84/Indian_Cobra%2C_crop.jpg",
                originalSHA256: "a6cc554e4f6f2a7dba0f88be4e43476d25d4177721dc3a57967f4958ce987b32",
                downloadedSHA256: "a6cc554e4f6f2a7dba0f88be4e43476d25d4177721dc3a57967f4958ce987b32",
                derivativeSHA256: "5d9430284213b5a49e5d105336fb6dcc615d962e30c11dd582812a75675ae20b",
                derivativeWidth: 1600, derivativeHeight: 1571,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "indian-chameleon", name: "Indian chameleon", scientificName: "Chamaeleo zeylanicus",
            group: "Reptile", asset: "AnimalPhotoIndianChameleon", collections: ["all-animals", "india-wildlife", "reptiles"],
            description: "A green scaly animal on a branch with a curled tail.", hint: "Look at its tail curled into a spiral.",
            attribution: AnimalPhotoAttribution(
                author: "arian.suresh (A.N. Suresh Kumar)", creditLine: "A.N.Suresh Kumar (arian.suresh@gmail.com), https://www.flickr.com/photos/ansk/",
                licenseName: "CC BY 2.0 Generic", licenseURL: "https://creativecommons.org/licenses/by/2.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:An_Indian_chameleon_wildlife_in_Andhra_Pradesh_India_2016.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/c/c6/An_Indian_chameleon_wildlife_in_Andhra_Pradesh_India_2016.jpg",
                downloadedURL: "https://upload.wikimedia.org/wikipedia/commons/c/c6/An_Indian_chameleon_wildlife_in_Andhra_Pradesh_India_2016.jpg",
                originalSHA256: "f4a812b031feb7f159a6f981be33a2ccfdcf19386ade2c13d096747dc78546f5",
                downloadedSHA256: "f4a812b031feb7f159a6f981be33a2ccfdcf19386ade2c13d096747dc78546f5",
                derivativeSHA256: "e111d4dda0d32b94ffb5301becca682736b89cf189ae1e06fa851e2ad4485799",
                derivativeWidth: 1600, derivativeHeight: 1066,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "bengal-monitor", name: "Bengal monitor", scientificName: "Varanus bengalensis",
            group: "Reptile", asset: "AnimalPhotoBengalMonitor", collections: ["all-animals", "india-wildlife", "reptiles"],
            description: "A scaly animal among leaves with a long forked tongue showing.", hint: "Look at its long forked tongue.",
            attribution: AnimalPhotoAttribution(
                author: "Charles J. Sharp", creditLine: "Charles J. Sharp",
                licenseName: "CC BY-SA 4.0 International", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Common_Indian_monitor_(Varanus_bengalensis).jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/1/11/Common_Indian_monitor_(Varanus_bengalensis).jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/1/11/Common_Indian_monitor_(Varanus_bengalensis).jpg/1280px-Common_Indian_monitor_%28Varanus_bengalensis%29.jpg",
                originalSHA256: nil,
                downloadedSHA256: "064dc1f3fa4544a2ccfcd99b46e91121bb5bb6a7e9844556f754f69ced93319b",
                derivativeSHA256: "333a18fb2fa578902e9f467e3e835c7e3813bad50a65209be10fe76ab6103484",
                derivativeWidth: 1280, derivativeHeight: 853,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "indian-bullfrog", name: "Indian bullfrog", scientificName: "Hoplobatrachus tigerinus",
            group: "Amphibian", asset: "AnimalPhotoIndianBullfrog", collections: ["all-animals", "india-wildlife", "little-neighbors"],
            description: "A brown animal crouching on a rock with folded back legs.", hint: "Look at the folded back legs.",
            attribution: AnimalPhotoAttribution(
                author: "P Jeganathan", creditLine: "P Jeganathan",
                licenseName: "CC BY-SA 3.0 Unported", licenseURL: "https://creativecommons.org/licenses/by-sa/3.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Indian_bull_frog_from_Kolli_Hills_JEG3162.JPG",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/0/08/Indian_bull_frog_from_Kolli_Hills_JEG3162.JPG",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/0/08/Indian_bull_frog_from_Kolli_Hills_JEG3162.JPG/1280px-Indian_bull_frog_from_Kolli_Hills_JEG3162.JPG",
                originalSHA256: nil,
                downloadedSHA256: "834b26a424d7b392c2d76620adbc9080be2be13c5190652b6eddfe1dda675074",
                derivativeSHA256: "f272e84271bdf62fe6ef56748afb423a0125388b313a12a72c0cbeb5f28f3c9c",
                derivativeWidth: 1280, derivativeHeight: 848,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "indian-palm-squirrel", name: "Indian palm squirrel", scientificName: "Funambulus palmarum",
            group: "Mammal", asset: "AnimalPhotoIndianPalmSquirrel", collections: ["all-animals", "india-wildlife", "little-neighbors"],
            description: "A small furry animal stretched along a branch with a bushy tail.", hint: "Look at the bushy tail hanging beside the branch.",
            attribution: AnimalPhotoAttribution(
                author: "Deepugn", creditLine: "Deepugn",
                licenseName: "CC BY-SA 4.0 International", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Indian-palm-squirrel-from-kottayam.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/e/ee/Indian-palm-squirrel-from-kottayam.jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/e/ee/Indian-palm-squirrel-from-kottayam.jpg/1280px-Indian-palm-squirrel-from-kottayam.jpg",
                originalSHA256: nil,
                downloadedSHA256: "9831da3be238e997bfce41d4e1ccb7d2cad103d9ade7433ee38a313035c38a49",
                derivativeSHA256: "8a6e49d06f152eb188a318705d2a4ed631e0d460fe22097b60c4f6b6eed5176a",
                derivativeWidth: 1280, derivativeHeight: 671,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "water-buffalo", name: "Water buffalo", scientificName: "Bubalus bubalis",
            group: "Mammal", asset: "AnimalPhotoWaterBuffalo", collections: ["all-animals", "farm-animals"],
            description: "A horned animal lowering its head toward plants.", hint: "Look at its long curved horns.",
            attribution: AnimalPhotoAttribution(
                author: "Shishirdasika", creditLine: "Shishirdasika",
                licenseName: "CC BY-SA 4.0 International", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Indian_Buffalo.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/0/0c/Indian_Buffalo.jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/0/0c/Indian_Buffalo.jpg/1280px-Indian_Buffalo.jpg",
                originalSHA256: nil,
                downloadedSHA256: "c0273f12ee98c802739b3be10e4324272dd54ac2cd938d078ad005cd91a85e30",
                derivativeSHA256: "4c99e2db9130c2098f0523a1d7c2ca0a6493a06c0b568a3a96e0e82de35d9781",
                derivativeWidth: 1199, derivativeHeight: 1600,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "cattle", name: "Cattle", scientificName: "Bos indicus",
            group: "Mammal", asset: "AnimalPhotoCattle", collections: ["all-animals", "farm-animals"],
            description: "Two brown horned animals standing among plants.", hint: "Look at the horns, hooves and hump behind the neck.",
            attribution: AnimalPhotoAttribution(
                author: "Mike Finn", creditLine: "Mike Finn",
                licenseName: "CC BY 2.0 Generic", licenseURL: "https://creativecommons.org/licenses/by/2.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:India_-_Kerala_-_Thekkady_-_zebu.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/b/ba/India_-_Kerala_-_Thekkady_-_zebu.jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/b/ba/India_-_Kerala_-_Thekkady_-_zebu.jpg/1280px-India_-_Kerala_-_Thekkady_-_zebu.jpg",
                originalSHA256: nil,
                downloadedSHA256: "289ec919b2c239297afe818d660702b7594a1697374ca2ca532c5237db881433",
                derivativeSHA256: "e98f1932ea0a805f37ee4ed24f6ae4c75a08050b5111ccebbf05317f6f46fd86",
                derivativeWidth: 1280, derivativeHeight: 853,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "goat", name: "Goat", scientificName: "Capra hircus",
            group: "Mammal", asset: "AnimalPhotoGoat", collections: ["all-animals", "farm-animals"],
            description: "A brown animal with short backward-curving horns standing on a stone ledge.", hint: "Look at its short curved horns and hooves.",
            attribution: AnimalPhotoAttribution(
                author: "Emőke Dénes", creditLine: "Emőke Dénes",
                licenseName: "CC BY-SA 4.0 International", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Capra_aegagrus_hircus_-_India_1.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/c/cd/Capra_aegagrus_hircus_-_India_1.jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/c/cd/Capra_aegagrus_hircus_-_India_1.jpg/1280px-Capra_aegagrus_hircus_-_India_1.jpg",
                originalSHA256: nil,
                downloadedSHA256: "c68494bcf87a3297940aef5041e39f8132bb72ca81731102f2be671749096642",
                derivativeSHA256: "e22e71ed550af8110a7fd20ef4f31adbf948679be2324060fe9e68d336926b75",
                derivativeWidth: 1280, derivativeHeight: 960,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "sheep", name: "Sheep", scientificName: "Ovis aries",
            group: "Mammal", asset: "AnimalPhotoSheep", collections: ["all-animals", "farm-animals"],
            description: "A close view of a woolly animal with pale ears and a pink nose.", hint: "Look at the wool around its face.",
            attribution: AnimalPhotoAttribution(
                author: "Francesco Canu", creditLine: "Francesco Canu",
                licenseName: "CC BY-SA 4.0 International", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Sardinian_Sheep_portrait.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/3/33/Sardinian_Sheep_portrait.jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/3/33/Sardinian_Sheep_portrait.jpg/1280px-Sardinian_Sheep_portrait.jpg",
                originalSHA256: nil,
                downloadedSHA256: "b95ae4ec3cd15ce20e35fbeed9704006509ba5243f6a70cabe940e2f79a3b7eb",
                derivativeSHA256: "8f0272f843a722135965fee1bb6b9ebeb9972b51aed5b775b859f17aaef2d050",
                derivativeWidth: 1280, derivativeHeight: 935,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "dromedary-camel", name: "Dromedary camel", scientificName: "Camelus dromedarius",
            group: "Mammal", asset: "AnimalPhotoDromedaryCamel", collections: ["all-animals", "farm-animals"],
            description: "A tan animal with a long neck sitting on sand, wearing a patterned saddle.", hint: "Look at its long neck and broad muzzle.",
            attribution: AnimalPhotoAttribution(
                author: "Clément Bardot", creditLine: "Clément Bardot",
                licenseName: "CC BY-SA 4.0 International", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Dromedary_in_Thar_desert.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/9/90/Dromedary_in_Thar_desert.jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/9/90/Dromedary_in_Thar_desert.jpg/1280px-Dromedary_in_Thar_desert.jpg",
                originalSHA256: nil,
                downloadedSHA256: "a6fc3f090b30f564a2a496eef69454752db9a50529550bba6252b3a1bb77a208",
                derivativeSHA256: "ca99437f5e291e79a51b2d4c099f5b1e413b89cd3ec5b4d4f5ec545fb0fa4907",
                derivativeWidth: 1280, derivativeHeight: 789,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "rhesus-macaque", name: "Rhesus macaque", scientificName: "Macaca mulatta",
            group: "Mammal", asset: "AnimalPhotoRhesusMacaque", collections: ["all-animals", "india-wildlife"],
            description: "A grey-brown animal with a pale face sitting on grass.", hint: "Look at its hands, feet and pale face.",
            attribution: AnimalPhotoAttribution(
                author: "Yann Forget", creditLine: "© Yann Forget / Wikimedia Commons / CC-BY-SA",
                licenseName: "CC BY-SA 4.0 International", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Rhesus_Macaque,_Agra,_India.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/d/d5/Rhesus_Macaque%2C_Agra%2C_India.jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/d/d5/Rhesus_Macaque%2C_Agra%2C_India.jpg/1280px-Rhesus_Macaque%2C_Agra%2C_India.jpg",
                originalSHA256: nil,
                downloadedSHA256: "640af56b7a059913af8831190baa6d17d1cce0f0dfb9e19209ac672769578199",
                derivativeSHA256: "9ea30496ad3003d5079149792fa0ae993603dee1f5cfc91442c8476e73808eaf",
                derivativeWidth: 1280, derivativeHeight: 853,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "red-panda", name: "Red panda", scientificName: "Ailurus fulgens",
            group: "Mammal", asset: "AnimalPhotoRedPanda", collections: ["all-animals", "india-wildlife"],
            description: "A red-brown furry animal with white face markings resting on wood.", hint: "Look at its white face markings and pointed ears.",
            attribution: AnimalPhotoAttribution(
                author: "Arpita Abrol", creditLine: "Arpita Abrol",
                licenseName: "CC BY-SA 4.0 International", licenseURL: "https://creativecommons.org/licenses/by-sa/4.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:Red_Panda_in_Nainital_Zoo_India.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/9/95/Red_Panda_in_Nainital_Zoo_India.jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/9/95/Red_Panda_in_Nainital_Zoo_India.jpg/1280px-Red_Panda_in_Nainital_Zoo_India.jpg",
                originalSHA256: nil,
                downloadedSHA256: "1fc76039cd6440e364be878ce9561bd2a9217d04af3f3c327076770f2bb9e26c",
                derivativeSHA256: "e6962c677541e9963cbc8031db61350d55448d6238cb4e964708c730ee8960b0",
                derivativeWidth: 1280, derivativeHeight: 848,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        ),
        entry(
            id: "gaur", name: "Gaur", scientificName: "Bos gaurus",
            group: "Mammal", asset: "AnimalPhotoGaur", collections: ["all-animals", "india-wildlife"],
            description: "A large brown animal with curved horns and pale lower legs.", hint: "Look at its pale lower legs below the dark coat.",
            attribution: AnimalPhotoAttribution(
                author: "Vivekkhushrang", creditLine: "Vivekkhushrang",
                licenseName: "CC0 1.0 Universal", licenseURL: "https://creativecommons.org/publicdomain/zero/1.0/",
                sourceURL: "https://commons.wikimedia.org/wiki/File:South_Indian_Gaur.jpg",
                originalURL: "https://upload.wikimedia.org/wikipedia/commons/c/c3/South_Indian_Gaur.jpg",
                downloadedURL: "https://thumb.wikimedia.org/wikipedia/commons/thumb/c/c3/South_Indian_Gaur.jpg/1280px-South_Indian_Gaur.jpg",
                originalSHA256: nil,
                downloadedSHA256: "fd0b6b1e1c319d6e1476e4b0a1db79ef0c637827b3515e491ff51cef9767d683",
                derivativeSHA256: "566a9ee80263f9a196e3bb74ba4da044b1a1eece1aa542909b2f5c6d0b415b78",
                derivativeWidth: 1280, derivativeHeight: 960,
                modificationDescription: "Aspect-preserving downscale only when the downloaded long edge exceeds 1600 pixels; JPEG recompression at quality 78. No upscaling, crop, retouching, or generated detail.",
                grantNote: "Exact Commons file page identifies the handed author and grants this individual file under the recorded license; the downloaded source and derivative are separately hashed."
            )
        )
    ]

    private static func entry(
        id: String, name: String, scientificName: String, group: String,
        asset: String, collections: [String], description: String, hint: String,
        attribution: AnimalPhotoAttribution
    ) -> AnimalExplorerEntry {
        let card = MemoryAnimal(
            id: "animal-photo-" + id, name: name, picture: .asset(asset),
            metadata: MemoryCardMetadata(
                // The historical deck key presents the Animals activity. It does
                // not assert that the wildlife photographs show domestic animals.
                deck: .domesticAnimals, category: "Animal photographs", kind: group,
                factCards: [
                    MemoryFactCard(title: "Animal group", value: group),
                    MemoryFactCard(title: "Scientific name", value: scientificName),
                    MemoryFactCard(title: "In this photo", value: description)
                ]
            )
        )
        return AnimalExplorerEntry(
            card: card, speciesID: id, collectionIDs: collections,
            neutralPhotoDescription: description, hint: hint,
            photoCredit: attribution.creditLine + " · " + attribution.licenseName,
            photoAttribution: attribution
        )
    }
}
