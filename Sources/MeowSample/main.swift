import Meow
import Foundation

do {
    try Meow.init("mongodb://localhost/meow")
    try Meow.database.drop()
    
    let boss = try User(email: "harriebob@example.com")
    boss.firstName = "Harriebob"
    boss.lastName = "Konijn"
    try boss.save()
    
    let bossHouse = House()
    bossHouse.owner = Reference(boss)
    try bossHouse.save()
    
    try bossHouse.delete()
    
    _ = try Flat.find { flat in
        return flat.id == "kaas"
    }
} catch {
    print("Whoops, \(error)")
}
