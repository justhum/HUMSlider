//: [Previous](@previous)

import UIKit
import PlaygroundSupport
import HUMSlider

let viewController = SliderViewController()
PlaygroundPage.current.liveView = viewController

//: ## Image Customization

/*:
 The APIs to set images on either side of the track come directly from `UISlider`. You should use the `minimumTrackImage` and `maximumTrackImage` in order to set these.

 Make sure to use a templatable image or it's gonna look pretty goofy.

 By default, `HUMSlider` will use the system `.red` color as the saturated color as you get closer to each side, and `.lightGray` as the desaturated color as you get farther away.
 */

let happy = UIImage(named: "moodHappy-dirtied")
let sad = UIImage(named: "moodSad-dirtied")

viewController.slider.maximumValueImage = happy
viewController.slider.minimumValueImage = sad


/*:
 You can also set your colors for the saturated and desaturated states:
*/

viewController.slider.saturatedColor = .blue
viewController.slider.desaturatedColor = .purple
//: [Next](@next)
