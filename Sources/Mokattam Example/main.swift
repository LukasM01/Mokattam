import Foundation
import Mokattam

let mokattam = Mokattam()
mokattam.showCursor = false

struct A {
    let a: String
    var b: String
    var c: String
}
var table = mokattam.append(element: Table<A>(columns: [
    Column(name: "a",formatter: {$0.a}),
    Column(name: "b",formatter: {$0.b}),
    Column(name: "c",formatter: {$0.c}),
]))
table.data = [
    A(a: "test", b: "bas", c: "sd"),
    A(a: "dfs", b: "fd", c: "sasd"),
]
sleep(1)
table.data.append(A(a: "test", b: "123", c: "ksad"))
sleep(1)
table.data[1].c = "a"
//var select = mokattam.append(element: Select(choices: [("a", 1), ("b", 2)])).read()
mokattam.close()

