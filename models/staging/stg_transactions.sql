with source as (
    select * from {{ ref('raw_transactions') }}
),

renamed as (
    select
        -- Primary Key
        cast(transaction_id as varchar) as transaction_id,
        cast(user_id as varchar) as user_id,

        -- Timestamps
        cast(created_at as timestamp) as transaction_created_at,
        cast(created_at as date) as transaction_date,

        -- Currency & Amount attributes
        cast(source_currency as varchar) as source_currency,
        cast(target_currency as varchar) as target_currency,
        cast(source_amount as decimal(18, 2)) as source_amount,
        cast(target_amount as decimal(18, 2)) as target_amount,
        cast(fx_rate as decimal(10, 4)) as fx_rate,
        cast(amount_eur as decimal(18, 2)) as amount_eur,

        -- Categorical dimensions
        lower(trim(payment_method)) as payment_method,
        lower(trim(device_channel)) as device_channel,
        lower(trim(status)) as transaction_status,

        -- Compliance & Anomaly Flags
        case when is_rapid_fire_alert = 1 then true else false end as is_rapid_fire_alert,
        case when is_pep_sanction_flag = 1 then true else false end as is_pep_sanction_flag

    from source
)

select * from renamed
