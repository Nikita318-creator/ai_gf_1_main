//
//  AudioWaveformView.swift
//  ChatBot20
//
//  Created by Mikita on 04/07/2026.
//

import UIKit
import SnapKit

class AudioWaveformView: UIView {
    
    // Замыкание, которое будет срабатывать при изменении прогресса пользователем
    var onProgressChanged: ((Float, _ isDragging: Bool) -> Void)?
    
    private let stackView = UIStackView()
    private var bars: [UIView] = []
    
    var progress: Float = 0 {
        didSet {
            updateBarsColor()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 3
        
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Генерируем фиксированную волну из 30 столбиков (чтобы заполнило всю ширину)
        for _ in 0..<30 {
            let bar = UIView()
            bar.backgroundColor = .white.withAlphaComponent(0.3)
            bar.layer.cornerRadius = 1.5
            stackView.addArrangedSubview(bar)
            
            bar.snp.makeConstraints { make in
                make.height.equalTo(CGFloat.random(in: 8...28))
                make.width.equalTo(3)
            }
            bars.append(bar)
        }
        
        // Добавляем жесты для перемотки
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        
        addGestureRecognizer(panGesture)
        addGestureRecognizer(tapGesture)
    }
    
    private func updateBarsColor() {
        let activeCount = Int(Float(bars.count) * progress)
        for (index, bar) in bars.enumerated() {
            if index < activeCount {
                bar.backgroundColor = .white // Проигранная часть
            } else {
                bar.backgroundColor = .white.withAlphaComponent(0.3) // Будущая часть
            }
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        let calculatedProgress = max(0, min(1, Float(location.x / bounds.width)))
        progress = calculatedProgress
        onProgressChanged?(calculatedProgress, false) // false — палец отпущен, перематываем сразу
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        let calculatedProgress = max(0, min(1, Float(location.x / bounds.width)))
        progress = calculatedProgress
        
        switch gesture.state {
        case .began, .changed:
            onProgressChanged?(calculatedProgress, true) // true — юзер тащит пальцем
        case .ended, .cancelled:
            onProgressChanged?(calculatedProgress, false) // false — отпустил
        default:
            break
        }
    }
}
