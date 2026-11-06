"""
Synthetic FinTech & Risk Data Generator
Author: Anouar Bouchaara
Purpose: Generate 100% synthetic multi-currency transaction, account, and alert data
         to demonstrate modern dbt modeling and analytics engineering patterns.
Zero dependencies on Wise internal systems or proprietary IP. Runs with standard library.
"""

import csv
import random
import uuid
from datetime import datetime, timedelta
import os

random.seed(42)

CURRENCIES = ["EUR", "GBP", "USD", "CAD", "AUD", "SGD"]
RATES_TO_EUR = {
    "EUR": 1.0,
    "GBP": 1.17,
    "USD": 0.92,
    "CAD": 0.68,
    "AUD": 0.60,
    "SGD": 0.69
}
PAYMENT_METHODS = ["bank_transfer", "debit_card", "instant_payout", "swift"]
RISK_BANDS = ["low", "medium", "high", "enhanced_due_diligence"]
CHANNELS = ["web_app", "ios", "android", "api_partner"]

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "seeds")
os.makedirs(OUTPUT_DIR, exist_ok=True)

def generate_users(count=1000):
    users = []
    start_date = datetime(2025, 1, 1)
    
    for i in range(1, count + 1):
        user_id = f"usr_{i:06d}"
        created_at = start_date + timedelta(days=random.randint(0, 365), seconds=random.randint(0, 86400))
        country = random.choice(["EE", "DE", "FR", "GB", "US", "ES", "NL", "LT", "LV", "FI"])
        base_currency = "EUR" if country in ["EE", "DE", "FR", "ES", "NL", "LT", "LV", "FI"] else ("GBP" if country == "GB" else "USD")
        risk_tier = random.choices(RISK_BANDS, weights=[0.75, 0.18, 0.05, 0.02])[0]
        
        users.append({
            "user_id": user_id,
            "registered_at": created_at.strftime("%Y-%m-%d %H:%M:%S"),
            "country_code": country,
            "base_currency": base_currency,
            "initial_risk_tier": risk_tier,
            "is_verified": 1 if random.random() > 0.03 else 0
        })
    return users

def generate_transactions(users, count=10000):
    txs = []
    base_time = datetime(2025, 1, 15)
    
    for i in range(1, count + 1):
        user = random.choice(users)
        tx_id = f"tx_{i:08d}"
        
        user_reg_time = datetime.strptime(user["registered_at"], "%Y-%m-%d %H:%M:%S")
        days_after_reg = random.randint(0, 300)
        tx_time = user_reg_time + timedelta(days=days_after_reg, hours=random.randint(0, 23), minutes=random.randint(0, 59))
        
        send_curr = user["base_currency"]
        recv_curr = random.choice([c for c in CURRENCIES if c != send_curr])
        
        # Power-law transaction amounts
        raw_val = random.expovariate(1.0 / 250) + 10
        send_amount = round(raw_val, 2)
        rate = round(RATES_TO_EUR[send_curr] / RATES_TO_EUR[recv_curr], 4)
        recv_amount = round(send_amount * rate, 2)
        amount_eur = round(send_amount * RATES_TO_EUR[send_curr], 2)
        
        # FinCrime Anomaly injection
        is_rapid_fire = 1 if (amount_eur > 4500 and random.random() < 0.25) else 0
        is_sanction_pep_flag = 1 if (user["initial_risk_tier"] in ["high", "enhanced_due_diligence"] and random.random() < 0.12) else 0
        status = "blocked_compliance" if (is_sanction_pep_flag or (amount_eur > 9500 and is_rapid_fire)) else ("completed" if random.random() > 0.02 else "refunded")
        
        txs.append({
            "transaction_id": tx_id,
            "user_id": user["user_id"],
            "created_at": tx_time.strftime("%Y-%m-%d %H:%M:%S"),
            "source_currency": send_curr,
            "target_currency": recv_curr,
            "source_amount": send_amount,
            "target_amount": recv_amount,
            "fx_rate": rate,
            "amount_eur": amount_eur,
            "payment_method": random.choice(PAYMENT_METHODS),
            "device_channel": random.choice(CHANNELS),
            "status": status,
            "is_rapid_fire_alert": is_rapid_fire,
            "is_pep_sanction_flag": is_sanction_pep_flag
        })
    return txs

if __name__ == "__main__":
    print("[*] Generating synthetic FinTech transaction and user seeds for dbt project...")
    users = generate_users(1200)
    txs = generate_transactions(users, 15000)
    
    users_path = os.path.join(OUTPUT_DIR, "raw_users.csv")
    with open(users_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=users[0].keys())
        writer.writeheader()
        writer.writerows(users)
    print(f"[✓] Written {len(users)} users to {users_path}")
    
    txs_path = os.path.join(OUTPUT_DIR, "raw_transactions.csv")
    with open(txs_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=txs[0].keys())
        writer.writeheader()
        writer.writerows(txs)
    print(f"[✓] Written {len(txs)} transactions to {txs_path}")
    print("[+] Synthetic dataset generated successfully. Ready for dbt seed loading.")
