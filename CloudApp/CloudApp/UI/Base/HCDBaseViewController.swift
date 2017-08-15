//
//  HCDBaseViewController.swift
//  CloudDisk-AutoSync
//
//  Created by Hanbiro Inc on 8/24/16.
//  Copyright © 2016 Hanbiro Inc. All rights reserved.
//

import Cocoa

//private enum Axis: StringLiteralType {
//    case x = "x"
//    case y = "y"
//}
//
//extension NSView {
//    private func shake(on axis: Axis) {
//        let animation = CAKeyframeAnimation(keyPath: "transform.translation.\(axis.rawValue)")
//        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
//        animation.duration = 0.6
//        animation.values = [-20, 20, -20, 20, -10, 10, -5, 5, 0]
//        layer?.add(animation, forKey: "shake")
//    }
//    func shakeOnXAxis() {
//        self.shake(on: .x)
//    }
//    func shakeOnYAxis() {
//        self.shake(on: .y)
//    }
//}

class HCDBaseViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func shack() {
        let numberOfShakes: Int = 8
        let durationOfShake: Float = 0.5
        let vigourOfShake: CGFloat = 0.05
        
        let frame:CGRect = (self.view.window?.frame)!
        let x = NSMinX(frame)
        let y = NSMinY(frame)
        let width = frame.size.width
        
        let shakePath = CGMutablePath()
        
        shakePath.move(to: CGPoint(x: x, y: y))
        for _ in 1...numberOfShakes{
            shakePath.addLine(to: CGPoint(x: x - width * vigourOfShake, y: y))
            shakePath.addLine(to: CGPoint(x: x + width * vigourOfShake, y: y))
        }
        shakePath.closeSubpath()
        
        let shakeAnimation = CAKeyframeAnimation()
        shakeAnimation.path = shakePath
        shakeAnimation.duration = CFTimeInterval(durationOfShake)
        
        self.view.window?.animations = ["frameOrigin": shakeAnimation]
        self.view.window?.animator().setFrameOrigin(self.view.window!.frame.origin)
    }
}
