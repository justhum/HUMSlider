//: [Previous](@previous)

//: [Previous](@previous)

import UIKit
import PlaygroundSupport
import HUMSlider

let viewController = SliderViewController()
PlaygroundPage.current.liveView = viewController


//: ## Track And Thumb Customization

/*:
 Lots of cool stuff is available through the `UISlider` API. You can change the background color of the track by changing the tint color:
 */

viewController.slider.tintColor = .green

/*:
 Or you can set the track image on either side:
 */

let customTrack = UIImage(named: "sliderTrack-dark")?.stretchableImage(withLeftCapWidth: 4, topCapHeight: 0)

viewController.slider.setMinimumTrackImage(customTrack, for: .normal)
viewController.slider.setMaximumTrackImage(customTrack, for: .normal)

/*:
 That looks neat, but it still looks a little weird with the default thumbnail. You can replace the thumbnail image with default APIs:
 */
let customThumb = UIImage(named: "sliderThumb-dark")
viewController.slider.setThumbImage(customThumb, for: .normal)


/*:
 If you look closely, that's a little off, because the image contains a drop shadow.

 This is where `HUMSlider` comes in - you can set the `pointAdjustmentForCustomThumb` to compensate for that image
 */

viewController.slider.pointAdjustmentForCustomThumb = 8








//: [Next](@next)
