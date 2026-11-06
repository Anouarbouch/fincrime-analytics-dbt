with source as (
    select * from {{ ref('raw_users') }}
),

renamed as (
    select
        -- Primary Key
        cast(user_id as varchar) as user_id,

        -- Timestamps
        cast(registered_at as timestamp) as user_registered_at,
        cast(registered_at as date) as registration_date,

        -- Geographic & Preferences
        upper(trim(country_code)) as country_code,
        upper(trim(base_currency)) as base_currency,
        lower(trim(initial_risk_tier)) as initial_risk_tier,

        -- Status Flags
        case when is_verified = 1 then true else false end as is_identity_verified

    from source
)

select * from renamed
