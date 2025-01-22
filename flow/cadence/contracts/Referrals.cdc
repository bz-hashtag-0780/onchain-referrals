import FungibleToken from "FungibleToken"

access(all) contract Referrals {

    access(all)
    let ReferralManagerStoragePath: StoragePath

    access(all)
	let ReferralManagerPublicPath: PublicPath

    access(self) var referrals: {Address: ReferralInfo}
    access(self) var referralCodes: {String: Address}

    access(all)
    struct ReferralInfo {
        access(all) let referrer: Address
        access(all) let date: UFix64
        
        init(referrer: Address) {
            self.referrer = referrer
            self.date = getCurrentBlock().timestamp
        }
    }

    access(all)
    struct PayoutRecord {
        access(all) let referral: Address
        access(all) let amount: UFix64
        access(all) let date: UFix64

        init(referral: Address, amount: UFix64) {
            self.referral = referral
            self.amount = amount
            self.date = getCurrentBlock().timestamp
        }
    }

    access(all)
    resource ReferralManager {
        access(self) var referralInfo: ReferralInfo?
        access(account) var payoutRecords: [PayoutRecord]

        init(referrer: Address) {
            self.referralInfo = nil
            self.payoutRecords = []
        }

        access(all)
        fun useReferralCode(referralCode: String) {
            if(
                Referrals.referralCodes[referralCode] != nil &&
                Referrals.referrals[self.owner!.address] == nil
                ) {
                let referrer = Referrals.referralCodes[referralCode]!
                let referralInfo = ReferralInfo(referrer: referrer)
                Referrals.referrals[self.owner!.address] = referralInfo
                self.referralInfo = referralInfo
            }
        }

        access(all)
        fun createReferralCode(referralCode: String) { // TODO Validate referralcode
            if(Referrals.referralCodes[referralCode] == nil) {
                Referrals.referralCodes[referralCode] = self.owner!.address
            }
        }

        access(all)
        fun receivePayout(referral: Address, amount: UFix64, tokens: @FungibleToken.Vault) {
            
        }
    }

    access(account)
    fun createPayoutRecord(referral: Address, amount: UFix64) { 
        if(Referrals.referrals[referral] != nil) {
            let referrer = Referrals.referrals[referral]!.referrer
            let payoutRecord = PayoutRecord(referral: referral, amount: amount)
            let referralRef = getAccount(referral).capabilities.get<&ReferralManager>(Referrals.ReferralManagerPublicPath).borrow()
            if(referralRef != nil) {
                referralRef!.payoutRecords.append(payoutRecord) //TODO confirm if we can even do this and make sure only this contract may mutate the resource, otherwise we need to find another way that scales
            }
        }
        
    }

    init() {
        self.ReferralManagerStoragePath = /storage/OnchainReferralManager
        self.ReferralManagerPublicPath = /public/OnchainReferralManager

        self.referrals = {}
        self.referralCodes = {}
    }
}