//: [Previous](@previous)

import UIKit
import PlaygroundSupport
import HUMSlider

let viewController = SliderViewController()
PlaygroundPage.current.liveView = viewController

//: ## Tick Customization

/*:
 The ticks default to the system `darkGrey` color, but you can make them whatever insane color you'd like:
 */

viewController.slider.tickColor = .orange

/*:
 By default, there are 9 ticks. You can use a lower or higher number if you'd like.
 Just make sure the number is odd or you'll get an assertion failure, because all the math for this depends on it being odd.
 */

viewController.slider.sectionCount = 5
viewController.slider.sectionCount = 15

// Will crash:
//viewController.slider.sectionCount = 10

/*:
 You can also choose to change the anmiation characteristics of the ticks. You can make the tick which is popping move super slow or super fast:
 */

viewController.slider.tickMovementAnimationDuration = 4
viewController.slider.tickMovementAnimationDuration = 0.2

