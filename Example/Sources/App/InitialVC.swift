import UIKit

class InitialVC: UIViewController {

    lazy var button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("show carousel", for: .normal)
        button.addTarget(self, action: #selector(buttonPressed), for: .touchUpInside)

        return button
    }()

    override func loadView() {
        view = UIView()
        view.backgroundColor = .yellow
        view.addSubview(button)
    }

    @objc func buttonPressed() {
        let newVC = ViewController()
        newVC.modalPresentationStyle = .overCurrentContext
        present(newVC, animated: true, completion: nil)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        button.sizeToFit()
        button.center = view.center
    }
}
