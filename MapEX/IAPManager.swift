import UIKit
import StoreKit

@objc protocol IAPManagerDelegate {
    //購入が完了した時
    @objc optional func iapManagerDidFinishPurchased()
    //ログインや購入確認のアラートが出た時
    @objc optional func iapManagerDidFinishItemLoad()
    //リストアが完了した時
    @objc optional func iapManagerDidFinishRestore(_ productIdentifiers: [String])
    //リストアに失敗した時
    @objc optional func iapManagerDidFailedRestore()
    //1度もアイテム購入したことがなく、リストアを実行した時
    @objc optional func iapManagerDidFailedRestoreNeverPurchase()
    //購入に失敗した時
    @objc optional func iapManagerDidFailedPurchased()
    //特殊な購入時の延期の時
    @objc optional func iapManagerDidDeferredPurchased()
}

class IAPManager: NSObject {

    fileprivate var isBuying  = false
    fileprivate var isRestoring = false
    fileprivate var completionForProductidentifiers : (([SKProduct]) -> Void)?
    fileprivate let paymentQueue = SKPaymentQueue.default()

    weak var delegate: IAPManagerDelegate?

    class var shared : IAPManager {
        struct Static {
            static let instance : IAPManager = IAPManager()
        }
        return Static.instance
    }

    private override init() {}
    //ユーザーが課金可能かどうか
    class var canMakePayments: Bool {
        get { return SKPaymentQueue.canMakePayments() }
    }
    //Product情報をApp Storeから取得
    func validateProductIdentifiers(productIdentifiers:[String], completion:(([SKProduct]) -> Void)?) {
        let request = SKProductsRequest(productIdentifiers: Set<String>(productIdentifiers))
        self.completionForProductidentifiers = completion
        request.delegate = self
        request.start()
    }
    //IDで指定したIAPプロダクトの購入を行います
    func buy(productIdentifier: String) {
        guard !self.isBuying else { print("購入処理中"); return }
        validateProductIdentifiers(productIdentifiers: [productIdentifier]) { [unowned self] products in
            let buyProduct: SKProduct? = {
                return products.filter { $0.productIdentifier == productIdentifier }.first
            }()

            //購入処理開始
            guard let product = buyProduct else { return }

            self.isBuying = true
            let payment = SKMutablePayment(product: product)
            self.paymentQueue.add(payment)
        }
    }
    //リストアを行います
    func restore() {
        guard !isRestoring else { print("リストア処理中"); return }
        self.isRestoring = true
        paymentQueue.restoreCompletedTransactions()
    }
}

extension IAPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                print("-----purchased-----")
                self.isBuying = false
                delegate?.iapManagerDidFinishPurchased?()
                queue.finishTransaction(transaction)
            case .purchasing:
                print("-----purchasing-----")
                delegate?.iapManagerDidFinishItemLoad?()
            case .restored:
                print("-----restored-----")
                queue.finishTransaction(transaction)
            case .failed:
                print("-----purchaseFailed-----")
                self.isBuying = false
                delegate?.iapManagerDidFailedPurchased?()
                queue.finishTransaction(transaction)
            case .deferred:
                print("-----purchaseDeferred-----")
                self.isBuying = false
                delegate?.iapManagerDidDeferredPurchased?()
                queue.finishTransaction(transaction)
            }
        }
    }
    //リストアの問い合わせが完了した時
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        self.isRestoring = false

        guard !queue.transactions.isEmpty else {
            delegate?.iapManagerDidFailedRestoreNeverPurchase?()
            return
        }
        self.isRestoring = false

        let productIdentifiers: [String] = {
            var identifiers: [String] = []
            queue.transactions.forEach {
                identifiers.append($0.payment.productIdentifier)
            }
            return identifiers
        }()

        delegate?.iapManagerDidFinishRestore?(productIdentifiers)
    }
    //リストアの問い合わせが失敗した時
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        print("-----restoreFailed-----")
        self.isRestoring = false
        delegate?.iapManagerDidFailedRestore?()
    }
    //AppStoreで必須
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return true
    }
}

extension IAPManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if !response.products.isEmpty {
            self.completionForProductidentifiers?(response.products)
        }
    }
}
