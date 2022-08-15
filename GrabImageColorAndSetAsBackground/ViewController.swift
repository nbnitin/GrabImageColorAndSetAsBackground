//
//  ViewController.swift
//  GrabImageColorAndSetAsBackground
//
//  Created by Nitin Bhatia on 15/08/22.
//

import UIKit

enum PIXEL_COLOR_GRAB_POSITION : Int {
    case INITIAL_POSITION
    case MIDDLE_POSITION
    case LAST_POSITION
}
let READ_COLOR_POSITION : PIXEL_COLOR_GRAB_POSITION = .LAST_POSITION

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var tasks: [URLSessionDataTask] = []
    var cells: [UITableViewCell] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        loadFlags()
    }

    func loadFlags() {
        [("Australia", URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/8/88/Flag_of_Australia_%28converted%29.svg/100px-Flag_of_Australia_%28converted%29.svg.png")!),
         ("Brazil", URL(string: "https://upload.wikimedia.org/wikipedia/en/thumb/0/05/Flag_of_Brazil.svg/100px-Flag_of_Brazil.svg.png")!),
         ("Canada", URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d9/Flag_of_Canada_%28Pantone%29.svg/100px-Flag_of_Canada_%28Pantone%29.svg.png")!),
         ("China", URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fa/Flag_of_the_People%27s_Republic_of_China.svg/100px-Flag_of_the_People%27s_Republic_of_China.svg.png")!),
         ("India", URL(string: "https://upload.wikimedia.org/wikipedia/en/thumb/4/41/Flag_of_India.svg/100px-Flag_of_India.svg.png")!),
         ("South Africa", URL(string: "https://upload.wikimedia.org/wikipedia/commons/thumb/a/af/Flag_of_South_Africa.svg/100px-Flag_of_South_Africa.svg.png")!),
         ("United Kingdom", URL(string: "https://upload.wikimedia.org/wikipedia/en/thumb/a/ae/Flag_of_the_United_Kingdom.svg/100px-Flag_of_the_United_Kingdom.svg.png")!),
         ("United States", URL(string: "https://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Flag_of_the_United_States.svg/100px-Flag_of_the_United_States.svg.png")!)
            ]
        .forEach(loadItems)
    }
    
    func loadItems(tuple : (name : String, imageURL : URL)) {
        let task = URLSession.shared.dataTask(with: tuple.imageURL, completionHandler :
        { data, response, error in
            guard let data = data, error == nil else { return }
            DispatchQueue.main.async() { [weak self] in
                self?.displayFlag(data: data, title: tuple.name)
            }
        })
        tasks.append(task)
        task.resume()
    }
    
    deinit {
        tasks.forEach {
            $0.cancel()
        }
    }

    func displayFlag(data: Data, title: String) {
        guard let image = UIImage(data: data) else { return }
        cells.append(UITableViewCell().setup(image: image, title: title))
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cells.count
    }

     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cells[indexPath.row]
    }

     func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        (cells[indexPath.row].imageView?.image?.size.height ?? 32) + 16
    }
}

extension UITableViewCell  {
    
    func setup(image: UIImage, title: String) -> UITableViewCell {
        let image = image.sRGB()
        textLabel?.textAlignment = .center
        textLabel?.text = title
        imageView?.image = image
        autoBackgroundAndTextColor()
        return self
    }
    
    func autoBackgroundAndTextColor() {
        guard let image = imageView?.image else { return }
        var posPoints : CGPoint!
        
        switch READ_COLOR_POSITION {
        case .INITIAL_POSITION:
            posPoints = CGPoint(x: 0, y: 0)
        case .MIDDLE_POSITION:
            posPoints = CGPoint(x: image.size.width/2,y: image.size.height/2)
        case .LAST_POSITION:
            posPoints = CGPoint(x: image.size.width - 1,y: image.size.height - 1)
        }
        
        backgroundColor = image.getPixelColor(
            pos: posPoints)

        var grayScale: CGFloat = 0
        var alpha: CGFloat = 0
        backgroundColor?.getWhite(&grayScale, alpha: &alpha)
        if (alpha > 0.5) {
            textLabel?.textColor = grayScale > 0.5 ? .black : .white
        }
    }
}

extension UIImage {
    func sRGB() -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    
    func getPixelColor(pos: CGPoint) -> UIColor {
        guard let cgImage = cgImage,
            let dataProvider = cgImage.dataProvider,
            let data = dataProvider.data else { return .white }
        let pixelData: UnsafePointer<UInt8> = CFDataGetBytePtr(data)

        let remaining = 8 - ((Int(size.width) * 2) % 8)
        let padding = (remaining < 8) ? remaining : 0
        let pixelInfo: Int = (((Int(size.width) * 2 + padding) * Int(pos.y * 2)) + Int(pos.x) * 2) * 4
            
        let r = CGFloat(pixelData[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(pixelData[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(pixelData[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(pixelData[pixelInfo+3]) / CGFloat(255.0)
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}


