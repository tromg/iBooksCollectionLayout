import UIKit
import iBooksLayout

class MyContentViewController: UIViewController {

    struct Appearance {
        static let textFont = UIFont.systemFont(ofSize: 20)
    }

    struct Model {
        let text: String
        let color: UIColor
    }

    private let label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = Appearance.textFont
        label.layer.cornerRadius = 16
        label.layer.borderWidth = 2
        label.layer.borderColor = UIColor.yellow.cgColor
        label.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        label.clipsToBounds = true

        return label
    }()

    private lazy var button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("CLOSE", for: .normal)
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)
        button.titleLabel?.font = .systemFont(ofSize: 25, weight: .bold)

        return button
    }()

    var closeActionBlock: (() -> Void)?

    override func loadView() {
        view = UIView()
        view.addSubview(label)
        view.addSubview(button)
    }

    func setModel(_ model: Model) {
        label.backgroundColor = model.color
        label.text = model.text
        view.setNeedsLayout()
    }

    @objc func buttonPressed() {
        closeActionBlock?()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        label.frame = view.bounds
        label.sizeToFit()
        button.sizeToFit()
        button.center = .init(x: view.bounds.width / 2, y: 30)
    }
}

extension MyContentViewController: BooksLayoutScrollableCellViewController {

    func height(for width: CGFloat) -> CGFloat {
        return label.sizeThatFits(.init(width: width, height: .infinity)).height
    }
}
