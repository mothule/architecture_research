//
//  ViewController.swift
//  simple_mvvm
//
//  Created by mothule on 2020/07/17.
//  Copyright © 2020 mothule. All rights reserved.
//

import UIKit

class SignUpViewModel {
    let title = Subject<String>("")
    let userId = Subject<String>("")
    let password = Subject<String>("")
    let confirmPassword = Subject<String>("")
    let agreed = Subject<Bool>(false)
    let signUpButtonTapped = Subject<Void>(())
    let isSignUpEnabled: Observable<Bool>
    let isIndicatorPresented = Subject<Bool>(false)
    
    
    init() {
        isSignUpEnabled =
            Observable.combineLatest(password.asObservable(), confirmPassword.asObservable()) { (password, confirmPassword) in
            return password.isEmpty == false && password == confirmPassword
        }

        signUpButtonTapped.subscribe(onNext: { [unowned self] _ in
            self.isIndicatorPresented.onNext(true)
            
            DispatchQueue.global().async {
                Thread.sleep(forTimeInterval: 2)
                DispatchQueue.main.async {
                    self.isIndicatorPresented.onNext(false)
                }
            }
        })
        
        password.onNext("")
        confirmPassword.onNext("")
    }
}

class SignUpViewController: UIViewController {
    private let vm = SignUpViewModel()
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var userIdTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var confirmPasswordTextField: UITextField!
    @IBOutlet private weak var agreeSwitch: UISwitch!
    @IBOutlet private weak var signUpButton: UIButton!
    private var indicatorContainerView: UIView?
    
    private var observers: [NSObjectProtocol] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        vm.title.subscribe(onNext: { [unowned self] title in
            self.titleLabel.text = title
        })
        
        vm.isIndicatorPresented.subscribe(onNext: { [unowned self] isPresented in
            if isPresented {
                self.indicatorContainerView = self.buildIndicatorView()
                self.view.addSubview(self.indicatorContainerView!)
                self.indicatorContainerView?.alpha = 0.0
                UIView.animate(withDuration: 0.3, animations: {
                    self.indicatorContainerView?.alpha = 1.0
                })
                
            } else {
                UIView.animate(withDuration: 0.3, animations: { [unowned self] in
                    self.indicatorContainerView?.alpha = 0.0
                }) { [unowned self] finished in
                    if finished {
                        self.indicatorContainerView?.removeFromSuperview()
                    }
                }
            }
        })
        
        vm.isSignUpEnabled.subscribe(onNext: { [unowned self] enabled in
            self.signUpButton.isEnabled = enabled
        })

        vm.userId.subscribe(onNext: { string in
            print(string)
        })
        vm.title.onNext("サインアップ")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(textChanged(_:)), name: UITextField.textDidChangeNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - View Helpers
    
    private func buildIndicatorView() -> UIView {
        let container = UIView(frame: self.view.frame)
        container.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        container.addSubview({
            let indicator = UIActivityIndicatorView(style: .large)
            indicator.color = UIColor.white
            indicator.startAnimating()
            indicator.center = container.center
            return indicator
        }())
        return container
    }
    
    // MARK: - Actions
    
    @objc private func textChanged(_ notification: Notification) {
        guard let textField = notification.object as? UITextField else { return }
        
        switch textField {
        case self.userIdTextField: self.vm.userId.onNext(textField.text ?? "")
        case self.passwordTextField: self.vm.password.onNext(textField.text ?? "")
        case self.confirmPasswordTextField: self.vm.confirmPassword.onNext(textField.text ?? "")
        default: break
        }
    }
    
    @IBAction func agreeChanged(_ sender: UISwitch) {
        vm.agreed.onNext(sender.isOn)
    }
    
    @IBAction func onTouchedSignUpButton(_ sender: UIButton) {
        vm.signUpButtonTapped.onNext(())
    }
}


