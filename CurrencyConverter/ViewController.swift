//
//  ViewController.swift
//  CurrencyConverter
//
//  Created by Mihail Babaev on 16.09.17.
//  Copyright © 2017 mbabaev. All rights reserved.
//

import UIKit

struct FixerResponse {
    let resultCurrency: String
    let allCurrencies: [String]
}

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var pickerFrom: UIPickerView!
    @IBOutlet weak var pickerTo: UIPickerView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var currencies = [String]() {
        didSet {
            if oldValue == currencies {
                pickerFrom.reloadAllComponents()
                pickerTo.reloadAllComponents()
            }
        }
    }
    
    var currenciesExceptBase: [String] {
        if currencies.isEmpty {
            return []
        }
        
        var result = currencies
        result.remove(at: pickerFrom.selectedRow(inComponent: 0))
        return result
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pickerFrom.delegate = self
        pickerTo.delegate = self
        
        pickerFrom.dataSource = self
        pickerTo.dataSource = self
        
        activityIndicator.hidesWhenStopped = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateCurrencies()
    }
    
    
    func updateCurrencies() {
        showProgress()
        
        self.retrivedCurrencyRate(baseCurrency: nil, toCurrency: nil) { [weak self] (value) in
            DispatchQueue.main.async(execute: {
                self?.dismiss(animated: true, completion: nil)
                
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.dismiss(animated: true, completion: nil)
                if strongSelf.currencies.isEmpty {
                    let alert = UIAlertController(title: "Error", message: "Unable to download currencies", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { action in
                        strongSelf.updateCurrencies()
                    }
                    alert.addAction(okAction)
                    
                    strongSelf.present(alert, animated: true, completion: nil)
                } else {
                    strongSelf.pickerTo.reloadAllComponents()
                    strongSelf.pickerFrom.reloadAllComponents()
                    strongSelf.requestCurrentCurrencyRate()
                }
            })
        }
    }
    
    func showProgress() {
        let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
    }
    
    
    
    func retrivedCurrencyRate(baseCurrency: String?, toCurrency: String?, completion: @escaping (String) -> Void) {
        self.requestCurrencyRates(baseCurrency: baseCurrency) { [weak self] (data, error) in
            var string = "No currency retrived!"
            
            if let currentError = error {
                string = currentError.localizedDescription
            } else {
                if let strongSelf = self {
                    string = strongSelf.parseCurrencyRatesResponse(data: data, toCurrency: toCurrency)
                }
            }
            
            completion(string)
        }
    }
    
    func requestCurrencyRates(baseCurrency: String?, parseHandler: @escaping (Data?, Error?) -> Void) {
        let baseCurrency = baseCurrency ?? "USD"
        let url = URL(string: "https://api.fixer.io/latest?base=" + baseCurrency)!
        
        let dataTask = URLSession.shared.dataTask(with: url) {
            (dataReceived, response, error) in
            parseHandler(dataReceived, error)
        }
        
        dataTask.resume()
    }
    
    func parseCurrencyRatesResponse(data: Data?, toCurrency: String?) -> String {
        var value = ""
        
        do {
            let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String : Any]
            if let parsedJSON = json {
                print("\(parsedJSON)")
                if let rates = parsedJSON["rates"] as? [String : Double] {
                    
                    guard let toCurrency = toCurrency else {
                        currencies = Array(rates.keys).sorted()
                        return value
                    }
                    
                    if let rate = rates[toCurrency] {
                        value = String(rate)
                    } else {
                        value = "No rate for currency \"\(toCurrency)\""
                    }
                } else {
                    value = "No \"\rates\" fields found"
                }
            } else {
                value = "No JSON value passed"
            }
        } catch {
            value = error.localizedDescription
        }
        
        return value
    }
    
    func requestCurrentCurrencyRate() {
        self.activityIndicator.startAnimating()
        self.label.text = ""
        
        let baseCurrencyIndex = self.pickerFrom.selectedRow(inComponent: 0)
        let toCurrencyIndex = self.pickerTo.selectedRow(inComponent: 0)
        
        let baseCurrency = self.currencies[baseCurrencyIndex]
        let toCurrency = self.currenciesExceptBase[toCurrencyIndex]
        
        self.retrivedCurrencyRate(baseCurrency: baseCurrency, toCurrency: toCurrency) { [weak self] (value) in
            DispatchQueue.main.async(execute: {
                self?.label.text = value
                self?.activityIndicator.stopAnimating()
            })
        }
    }
    
    // MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView === pickerTo {
            return self.currenciesExceptBase.count
        }
        
        return currencies.count
    }
    
    // MARK: - UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView === pickerTo {
            return self.currenciesExceptBase[row]
        }
        
        return currencies[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView === pickerFrom {
            self.pickerTo.reloadAllComponents()
        }
        
        self.requestCurrentCurrencyRate()
    }
}

