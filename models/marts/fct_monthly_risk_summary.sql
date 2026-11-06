with velocity as (
    select * from {{ ref('int_user_transaction_velocity') }}
),

users as (
    select * from {{ ref('stg_users') }}
),

joined as (
    select
        v.transaction_id,
        v.user_id,
        v.transaction_created_at,
        v.transaction_date,
        v.amount_eur,
        v.transaction_status,
        v.is_rapid_fire_alert,
        v.is_pep_sanction_flag,
        v.is_high_velocity_risk,
        v.is_suspected_smurfing_structuring,
        v.rolling_7d_volume_eur,
        v.rolling_7d_transaction_count,
        
        u.country_code,
        u.initial_risk_tier,
        u.is_identity_verified,
        date_trunc('month', v.transaction_date) as reporting_month

    from velocity v
    left join users u on v.user_id = u.user_id
),

monthly_aggregation as (
    select
        reporting_month,
        country_code,
        initial_risk_tier,

        -- Transaction Volume Metrics
        count(distinct transaction_id) as total_transaction_count,
        count(distinct user_id) as active_transacting_users,
        sum(amount_eur) as gross_transaction_volume_eur,
        avg(amount_eur) as average_transaction_value_eur,

        -- Risk & Alert Metrics
        count(distinct case when is_rapid_fire_alert then transaction_id end) as count_rapid_fire_alerts,
        count(distinct case when is_pep_sanction_flag then transaction_id end) as count_pep_sanction_alerts,
        count(distinct case when is_high_velocity_risk then transaction_id end) as count_high_velocity_alerts,
        count(distinct case when is_suspected_smurfing_structuring then transaction_id end) as count_structuring_alerts,
        count(distinct case when transaction_status = 'blocked_compliance' then transaction_id end) as count_blocked_transactions,
        sum(case when transaction_status = 'blocked_compliance' then amount_eur else 0 end) as total_blocked_volume_eur,

        -- Derived Alert Ratios
        round(
            100.0 * count(distinct case when transaction_status = 'blocked_compliance' then transaction_id end) / nullif(count(distinct transaction_id), 0),
            3
        ) as blocked_transaction_rate_pct

    from joined
    group by 1, 2, 3
)

select * from monthly_aggregation
order by reporting_month desc, gross_transaction_volume_eur desc
