import UIKit
import HUMSlider

public class SliderViewController : UIViewController {

    public lazy var slider: HUMSlider = {
        let slider = HUMSlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.value = slider.maximumValue / 2

        return slider
    }()

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        self.setupConstraints()
    }

    private func setupConstraints() {
        self.view.addSubview(self.slider)

        NSLayoutConstraint.activate([
            self.slider.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 20),
            self.slider.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -20),
            self.slider.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 40),
        ])
    }
}
