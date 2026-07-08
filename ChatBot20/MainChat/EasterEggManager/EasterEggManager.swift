//
//  EasterEggManager.swift
//  ChatBot20
//
//  Created by Mikita on 08/07/2026.
//

import UIKit

enum EasterEgg: String, CaseIterable {
    case fart, devil, tripleSix = "666", angel, coin, naked, help, sos
    case love, kiss, money, cat, fire, boo, alien, drunk, secret, matrix
    case dog, ghost, poop, bomb, beer, dynamic = "clown", heart, nerd, robot, star
    case flash, invert, zoom, blur, wave, spin, glitch, freeze, bounce, disco
    case moneyBag = "jackpot", party, skull, snake, alien2 = "ufo", broken = "break", dynamic2 = "pig", lightning = "storm", bug, rocket = "moon"
    case blackout, earthquake = "quake", rotate = "flip", pixelate = "pixel", heartbeat = "pulse", slide, phantom, melt, matrix2 = "system", neon
    case hi, hello, hey, greeting = "greetings", yo, sup, whatsUp = "whats up", howdy, hru = "how are you", doingGood = "how is it going"
    
    private var localizationTriggerKey: String {
        return "jokes.\(self.rawValue).triggers"
    }
    
    static func find(in text: String) -> EasterEgg? {
        for egg in EasterEgg.allCases {
            // Используем только твой метод .localize() для получения строки триггеров
            let localizedTriggersString = egg.localizationTriggerKey.localize()
            
            let triggers = localizedTriggersString
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            
            if triggers.contains(text) {
                return egg
            }
        }
        return nil
    }
}

final class EasterEggManager {
    
    static let shared = EasterEggManager()
    
    private init() {}
    
    func checkAndExecute(text: String, in view: UIView, avatarView: UIView?, tableView: UITableView?, toastHandler: @escaping (String, CGFloat) -> Void) {
        let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let egg = EasterEgg.find(in: cleanedText) else { return }
        
        WebHookAnaliticksService.shared.sendErrorReport(messageText: "🙈❤️ EasterEgg found: \(egg)\nfor user: \(WebHookAnaliticksService.shared.randomID)\n\(Locale.preferredLanguages.first ?? "???")")
        
        AnalyticService.shared.logEvent(
            name: "EasterEgg found",
            properties: [
                "egg":"\(egg)"
            ]
        )
        
        switch egg {
        case .fart:
            showEmojiRain(emoji: "💨", in: view)
            
        case .devil, .tripleSix:
            makeScreenRedAndShake(in: view)
            
        case .angel:
            showEmojiRain(emoji: "👼✨", in: view)
            
        case .coin:
            showEmojiRain(emoji: "🪙", in: view)
            CoinsService.shared.addCoins(1)
            toastHandler("jokes.coin.toast".localize(), 0.9)
            
        case .naked:
            showEmojiRain(emoji: "🙈❤️", in: view)
            toastHandler("jokes.naked.toast".localize(), 0.9)
            
        case .help, .sos:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            UIView.animate(withDuration: 0.2, animations: {
                view.transform = CGAffineTransform(translationX: -20, y: 300).rotated(by: -0.2)
                view.alpha = 0.5
            }) { _ in
                UIView.animate(withDuration: 0.6, delay: 0.4, options: .curveEaseOut, animations: {
                    view.transform = .identity
                    view.alpha = 1.0
                })
            }
            toastHandler("jokes.help.toast".localize(), 1.0)
            
        case .love:
            showEmojiRain(emoji: "❤️💖🥰", in: view)
            
        case .kiss:
            showEmojiRain(emoji: "💋", in: view)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
        case .money:
            showEmojiRain(emoji: "💵💸", in: view)
            
        case .cat:
            showEmojiRain(emoji: "🐱🐾", in: view)
            toastHandler("jokes.cat.toast".localize(), 0.8)
            
        case .fire:
            showEmojiRain(emoji: "🔥", in: view)
            guard let avatarView = avatarView else { return }
            UIView.animate(withDuration: 0.3, animations: {
                avatarView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            }) { _ in
                UIView.animate(withDuration: 0.3) {
                    avatarView.transform = .identity
                }
            }
            
        case .boo:
            makeScreenRedAndShake(in: view)
            toastHandler("jokes.boo.toast".localize(), 0.95)
            
        case .alien:
            showEmojiRain(emoji: "👽🛸", in: view)
            guard let tableView = tableView else { return }
            UIView.animate(withDuration: 0.5, animations: {
                tableView.transform = CGAffineTransform(translationX: 0, y: -100)
            }) { _ in
                UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseIn) {
                    tableView.transform = .identity
                }
            }
            
        case .drunk:
            let anim = CAKeyframeAnimation(keyPath: "transform.rotation")
            anim.duration = 1.5
            anim.values = [-0.05, 0.05, -0.03, 0.03, 0]
            view.layer.add(anim, forKey: "drunk_effect")
            toastHandler("jokes.drunk.toast".localize(), 0.8)
            
        case .secret:
            toastHandler("jokes.secret.toast".localize(), 0.8)
            
        case .matrix:
            toastHandler("jokes.matrix.toast".localize(), 1.0)
            
        case .dog:
            showEmojiRain(emoji: "🐶🐾", in: view)
            toastHandler("jokes.dog.toast".localize(), 0.8)
            
        case .ghost:
            showEmojiRain(emoji: "👻", in: view)
            
        case .poop:
            showEmojiRain(emoji: "💩", in: view)
            toastHandler("jokes.poop.toast".localize(), 0.8)
            
        case .bomb:
            showEmojiRain(emoji: "💣💥", in: view)
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            
        case .beer:
            showEmojiRain(emoji: "🍻🍺", in: view)
            toastHandler("jokes.beer.toast".localize(), 0.8)
            
        case .dynamic:
            showEmojiRain(emoji: "🤡", in: view)
            toastHandler("jokes.clown.toast".localize(), 0.8)
            
        case .heart:
            showEmojiRain(emoji: "💔", in: view)
            toastHandler("jokes.heart.toast".localize(), 0.8)
            
        case .nerd:
            showEmojiRain(emoji: "🤓📚", in: view)
            toastHandler("jokes.nerd.toast".localize(), 0.8)
            
        case .robot:
            showEmojiRain(emoji: "🤖", in: view)
            toastHandler("jokes.robot.toast".localize(), 0.8)
            
        case .star:
            showEmojiRain(emoji: "✨⭐", in: view)
            
        case .flash:
            let flash = UIView(frame: view.bounds)
            flash.backgroundColor = .white
            view.addSubview(flash)
            UIView.animate(withDuration: 0.4, animations: { flash.alpha = 0 }) { _ in flash.removeFromSuperview() }
            
        case .invert:
            view.layer.filters = [CIFilter(name: "CIColorInvert") as Any]
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                view.layer.filters = nil
            }
            toastHandler("jokes.invert.toast".localize(), 0.9)
            
        case .zoom:
            UIView.animate(withDuration: 0.2, animations: {
                view.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
            }) { _ in
                UIView.animate(withDuration: 0.3, delay: 0.2, options: .curveEaseOut, animations: {
                    view.transform = .identity
                })
            }
            
        case .blur:
            let blurEffect = UIBlurEffect(style: .light)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = view.bounds
            blurView.alpha = 0
            view.addSubview(blurView)
            UIView.animate(withDuration: 0.3, animations: { blurView.alpha = 1.0 }) { _ in
                UIView.animate(withDuration: 0.3, delay: 0.6, options: [], animations: { blurView.alpha = 0 }) { _ in
                    blurView.removeFromSuperview()
                }
            }
            toastHandler("jokes.blur.toast".localize(), 0.8)
            
        case .wave:
            let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
            anim.duration = 0.8
            anim.values = [0, 40, -40, 30, -30, 20, -20, 0]
            view.layer.add(anim, forKey: "wave_effect")
            
        case .spin:
            UIView.animate(withDuration: 0.6, animations: {
                view.transform = CGAffineTransform(rotationAngle: .pi)
            }) { _ in
                UIView.animate(withDuration: 0.4) {
                    view.transform = .identity
                }
            }
            toastHandler("jokes.spin.toast".localize(), 0.9)
            
        case .glitch:
            let haptic = UIImpactFeedbackGenerator(style: .medium)
            for i in 0..<6 {
                DispatchQueue.main.asyncAfter(deadline: .now() + (Double(i) * 0.08)) {
                    haptic.impactOccurred()
                    let offsetX = CGFloat.random(in: -15...15)
                    let offsetY = CGFloat.random(in: -15...15)
                    view.transform = CGAffineTransform(translationX: offsetX, y: offsetY)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                view.transform = .identity
            }
            toastHandler("jokes.glitch.toast".localize(), 0.9)
            
        case .freeze:
            let iceView = UIView(frame: view.bounds)
            iceView.backgroundColor = UIColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 0.25)
            iceView.alpha = 0
            view.addSubview(iceView)
            UIView.animate(withDuration: 0.4, animations: { iceView.alpha = 1.0 }) { _ in
                UIView.animate(withDuration: 0.5, delay: 0.8, options: [], animations: { iceView.alpha = 0 }) { _ in
                    iceView.removeFromSuperview()
                }
            }
            toastHandler("jokes.freeze.toast".localize(), 0.9)
            
        case .bounce:
            UIView.animate(withDuration: 0.15, animations: {
                view.transform = CGAffineTransform(translationX: 0, y: -50)
            }) { _ in
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.5, options: [], animations: {
                    view.transform = .identity
                })
            }
            
        case .disco:
            let colors: [UIColor] = [.magenta, .cyan, .yellow, .purple]
            let discoView = UIView(frame: view.bounds)
            view.addSubview(discoView)
            for i in 0..<4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + (Double(i) * 0.2)) {
                    discoView.backgroundColor = colors[i].withAlphaComponent(0.2)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                discoView.removeFromSuperview()
            }
            toastHandler("jokes.disco.toast".localize(), 0.9)
            
        case .moneyBag:
            showEmojiRain(emoji: "💰💎💵", in: view)
            toastHandler("jokes.moneyBag.toast".localize(), 0.95)
            
        case .party:
            showEmojiRain(emoji: "🎉🥳🎊", in: view)
            toastHandler("jokes.party.toast".localize(), 0.9)
            
        case .skull:
            showEmojiRain(emoji: "💀☠️", in: view)
            toastHandler("jokes.skull.toast".localize(), 0.85)
            
        case .snake:
            showEmojiRain(emoji: "🐍", in: view)
            toastHandler("jokes.snake.toast".localize(), 0.8)
            
        case .alien2:
            showEmojiRain(emoji: "🛸👽", in: view)
            toastHandler("jokes.alien2.toast".localize(), 0.9)
            
        case .broken:
            showEmojiRain(emoji: "💔😭🥺", in: view)
            toastHandler("jokes.broken.toast".localize(), 0.9)
            
        case .dynamic2:
            showEmojiRain(emoji: "🐷🐽", in: view)
            toastHandler("jokes.pig.toast".localize(), 0.8)
            
        case .lightning:
            showEmojiRain(emoji: "⚡⛈️", in: view)
            makeScreenRedAndShake(in: view)
            toastHandler("jokes.lightning.toast".localize(), 0.9)
            
        case .bug:
            showEmojiRain(emoji: "🪳🐛🐜", in: view)
            toastHandler("jokes.bug.toast".localize(), 0.95)
            
        case .rocket:
            showEmojiRain(emoji: "🚀🌕", in: view)
            toastHandler("jokes.rocket.toast".localize(), 0.9)
            
        case .blackout:
            let blackView = UIView(frame: view.bounds)
            blackView.backgroundColor = .black
            view.addSubview(blackView)
            toastHandler("jokes.blackout.toast".localize(), 1.0)
            UIView.animate(withDuration: 1.0, delay: 0.5, options: [], animations: {
                blackView.alpha = 0
            }) { _ in
                blackView.removeFromSuperview()
            }
            
        case .earthquake:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            let anim = CAKeyframeAnimation(keyPath: "transform.translation.y")
            anim.duration = 0.8
            anim.values = [0, -30, 30, -20, 20, -10, 10, 0]
            view.layer.add(anim, forKey: "quake_effect")
            toastHandler("jokes.earthquake.toast".localize(), 0.9)
            
        case .rotate:
            let rotateAnim = CAKeyframeAnimation(keyPath: "transform.rotation.z")
            rotateAnim.values = [0, Double.pi, Double.pi, 0]
            rotateAnim.keyTimes = [0, 0.3, 0.7, 1.0]
            rotateAnim.duration = 1.6
            rotateAnim.calculationMode = .linear
            view.layer.add(rotateAnim, forKey: "rotate_effect")
            toastHandler("jokes.rotate.toast".localize(), 0.85)
            
        case .pixelate:
            UIView.animate(withDuration: 0.2, animations: {
                view.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                view.alpha = 0.7
            }) { _ in
                UIView.animate(withDuration: 0.2, delay: 0.4, options: [], animations: {
                    view.transform = .identity
                    view.alpha = 1.0
                })
            }
            toastHandler("jokes.pixelate.toast".localize(), 0.9)
            
        case .heartbeat:
            let pulseAnim = CAKeyframeAnimation(keyPath: "transform.scale")
            pulseAnim.values = [1.0, 1.05, 1.0, 1.05, 1.0]
            pulseAnim.keyTimes = [0, 0.2, 0.4, 0.6, 1.0]
            pulseAnim.duration = 0.6
            view.layer.add(pulseAnim, forKey: "heartbeat")
            toastHandler("jokes.heartbeat.toast".localize(), 0.9)
            
        case .slide:
            UIView.animate(withDuration: 0.3, animations: {
                view.transform = CGAffineTransform(translationX: view.bounds.width, y: 0)
            }) { _ in
                view.transform = CGAffineTransform(translationX: -view.bounds.width, y: 0)
                UIView.animate(withDuration: 0.3) {
                    view.transform = .identity
                }
            }
            
        case .phantom:
            let ghostView = UIView(frame: view.bounds)
            ghostView.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.2)
            view.addSubview(ghostView)
            UIView.animate(withDuration: 0.5, animations: {
                ghostView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                ghostView.alpha = 0
            }) { _ in
                ghostView.removeFromSuperview()
            }
            toastHandler("jokes.phantom.toast".localize(), 0.8)
            
        case .melt:
            let meltAnim = CAKeyframeAnimation(keyPath: "transform.translation.y")
            meltAnim.values = [0, 60, 60, 0]
            meltAnim.keyTimes = [0, 0.3, 0.7, 1.0]
            meltAnim.duration = 1.4
            
            let opacityAnim = CAKeyframeAnimation(keyPath: "opacity")
            opacityAnim.values = [1.0, 0.6, 0.6, 1.0]
            opacityAnim.keyTimes = [0, 0.3, 0.7, 1.0]
            opacityAnim.duration = 1.4
            
            view.layer.add(meltAnim, forKey: "melt_y_effect")
            view.layer.add(opacityAnim, forKey: "melt_opacity_effect")
            toastHandler("jokes.melt.toast".localize(), 0.9)
            
        case .matrix2:
            let greenOverlay = UIView(frame: view.bounds)
            greenOverlay.backgroundColor = UIColor.green.withAlphaComponent(0.15)
            view.addSubview(greenOverlay)
            UIView.animate(withDuration: 0.6, animations: { greenOverlay.alpha = 0 }) { _ in greenOverlay.removeFromSuperview() }
            toastHandler("jokes.matrix2.toast".localize(), 1.0)
            
        case .neon:
            let neonView = UIView(frame: view.bounds)
            neonView.layer.borderColor = UIColor.cyan.cgColor
            neonView.layer.borderWidth = 10
            neonView.backgroundColor = .clear
            view.addSubview(neonView)
            
            UIView.animate(withDuration: 0.2, animations: { neonView.layer.borderColor = UIColor.systemPink.cgColor }) { _ in
                UIView.animate(withDuration: 0.2, animations: { neonView.layer.borderColor = UIColor.systemYellow.cgColor }) { _ in
                    neonView.removeFromSuperview()
                }
            }
            toastHandler("jokes.neon.toast".localize(), 0.95)
            
        case .hi, .hello:
            showEmojiRain(emoji: "👋✨❤️", in: view)
            guard let avatarView = avatarView else { return }
            UIView.animate(withDuration: 0.25, animations: {
                avatarView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }) { _ in
                UIView.animate(withDuration: 0.2) {
                    avatarView.transform = .identity
                }
            }
            
        case .hey, .yo, .howdy:
            showEmojiRain(emoji: "✌️😊✨", in: view)
            guard let avatarView = avatarView else { return }
            let anim = CAKeyframeAnimation(keyPath: "transform.rotation")
            anim.duration = 0.4
            anim.values = [-0.1, 0.1, 0]
            avatarView.layer.add(anim, forKey: "avatar_nod")
            
        case .sup, .whatsUp, .greeting:
            showEmojiRain(emoji: "😎🔥", in: view)
            toastHandler("jokes.sup.toast".localize(), 0.8)
            
        case .hru, .doingGood:
            showEmojiRain(emoji: "🥰✨🌸", in: view)
            let pulse = CAKeyframeAnimation(keyPath: "transform.scale")
            pulse.values = [1.0, 1.02, 1.0]
            pulse.duration = 0.4
            view.layer.add(pulse, forKey: "welcome_pulse")
            toastHandler("jokes.hru.toast".localize(), 0.85)
        }
    }
    
    private func showEmojiRain(emoji: String, in view: UIView) {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: view.bounds.width, height: 1)
        
        let cell = CAEmitterCell()
        cell.birthRate = 15
        cell.lifetime = 4.0
        cell.velocity = 150
        cell.velocityRange = 50
        cell.emissionLongitude = .pi
        
        cell.contents = imageFromEmoji(emoji)?.cgImage
        cell.scale = 0.5
        cell.scaleRange = 0.3
        
        emitter.emitterCells = [cell]
        view.layer.addSublayer(emitter)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            emitter.removeFromSuperlayer()
        }
    }

    private func imageFromEmoji(_ emoji: String) -> UIImage? {
        let size = CGSize(width: 40, height: 40)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.clear.set()
        let rect = CGRect(origin: .zero, size: size)
        UIRectFill(rect)
        (emoji as NSString).draw(in: rect, withAttributes: [.font: UIFont.systemFont(ofSize: 35)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    private func makeScreenRedAndShake(in view: UIView) {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        let flashView = UIView(frame: view.bounds)
        flashView.backgroundColor = UIColor.red.withAlphaComponent(0.3)
        view.addSubview(flashView)
        
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.6
        animation.values = [-20, 20, -20, 20, -10, 10, -5, 5, 0]
        view.layer.add(animation, forKey: "shake")
        
        UIView.animate(withDuration: 0.6, animations: {
            flashView.alpha = 0
        }) { _ in
            flashView.removeFromSuperview()
        }
    }
}
