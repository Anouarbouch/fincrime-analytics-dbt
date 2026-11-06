with transactions as (
    select * from {{ ref('stg_transactions') }}
),

windowed as (
    select
        transaction_id,
        user_id,
        transaction_created_at,
        transaction_date,
        amount_eur,
        transaction_status,
        is_rapid_fire_alert,
        is_pep_sanction_flag,

        -- Transaction sequence order per user
        row_number() over (
            partition by user_id
            order by transaction_created_at asc
        ) as user_transaction_sequence_number,

        -- Previous transaction timestamp to evaluate burst velocity
        lag(transaction_created_at) over (
            partition by user_id
            order by transaction_created_at asc
        ) as previous_transaction_created_at,

        -- Rolling 7-day cumulative spend in EUR
        sum(amount_eur) over (
            partition by user_id
            order by transaction_created_at asc
            range between interval 7 days preceding and current row
        ) as rolling_7d_volume_eur,

        -- Rolling 7-day transaction count
        count(transaction_id) over (
            partition by user_id
            order by transaction_created_at asc
            range between interval 7 days preceding and current row
        ) as rolling_7d_transaction_count

    from transactions
),

enriched as (
    select
        *,
        -- Seconds elapsed since prior transaction
        date_diff('second', previous_transaction_created_at, transaction_created_at) as seconds_since_last_transaction,

        -- Velocity Anomaly Rule: > 3 transactions in 7 days totaling > 10,000 EUR
        case
            when rolling_7d_transaction_count >= 3 and rolling_7d_volume_eur >= 10000.00
            then true
            else false
        end as is_high_velocity_risk,

        -- Structuring Alert: multiple sub-threshold transactions occurring within 1 hour
        case
            when date_diff('second', previous_transaction_created_at, transaction_created_at) <= 3600
                 and amount_eur between 4000.00 and 9999.00
            then true
            else false
        end as is_suspected_smurfing_structuring

    from windowed
)

select * from enriched
