import UIKit
import PlaygroundSupport
import HUMSlider

//: # Interactive README
/*:
 ![Swift Island Logo](SwiftIsland.png)
 Made as part of [Swift Island](https://swiftisland.nl/) 2018.

 Note that this Playground takes advantage of functionality in Xcode 10 which allows you to run a playground only up to a certain point, or to only run a single line.

 Note that for this to work, you need to set this playground to run manually rather than automatically.

 Also, in 10b2 there's a weird bug where something in the outer `Sources` folder won't properly compile
 */

//: ## HUMSlider
/*:
 `HUMSlider` is a class which allows a number of additional customizations to UISlider beyond the standard options available in UIKit.

 By default, the slider adds some ticks which automatically appear when the user touches the slider, and which pop up as the user drags underneath the ticks. The ticks disappear when the user lifts their finger.

 This is the basic slider in a view controller which you can customize in the following pages:
 */

let viewController = SliderViewController()
PlaygroundPage.current.liveView = viewController

/*:
 There are also several other fun features available to you:

 1. [Saturating Side Images](ImageCustomization)
 2. [Customizing The Ticks](TickCustomization)
 2. [Customizing The Track](TrackCustomization)
 */

//: [Next: Saturating Side Images](@next)
