-- ===============================================================================================================================================================================================
--                                              -: Step 1. Core Business Risk Questions :-
-- ===============================================================================================================================================================================================
-- 1.1 How risky is our current loan portfolio?
SELECT
    COUNT(DISTINCT l.loan_id) AS total_loans,
    COUNT(d.loan_id) AS defaulted_loans,
    ROUND(COUNT(d.loan_id) * 100.0 / COUNT(DISTINCT l.loan_id), 2) AS default_rate_pct
FROM loans l
LEFT JOIN defaults d ON l.loan_id = d.loan_id;

-- 44 loans out of a total 800 loans are defaulted, making around 5.50%.
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1.2 Does credit score actually separate risk?
SELECT 
    CASE
        WHEN c.credit_score < 600 THEN 'Low'
        WHEN c.credit_score BETWEEN 600 AND 699 THEN 'Medium'
        ELSE 'High'
    END AS credit_score_band,
    COUNT(DISTINCT l.loan_id) AS total_loans,
    COUNT(d.loan_id) AS defaulted_loans,
    ROUND(COUNT(d.loan_id) * 100.0 / COUNT(DISTINCT l.loan_id),
            2) AS default_rate_pct
FROM
    loans l
        JOIN
    customers c ON l.customer_id = c.customer_id
        LEFT JOIN
    defaults d ON l.loan_id = d.loan_id
GROUP BY credit_score_band
ORDER BY default_rate_pct DESC;

-- Yes; Lower credit scores = Higher default rates. (making around 19.75% !)
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1.3 Does low income actually spike the default rate?
SELECT 
    CASE
        WHEN c.annual_income < 40000 THEN 'Low Income'
        WHEN c.annual_income BETWEEN 40000 AND 80000 THEN 'Mid Income'
        ELSE 'High Income'
    END AS income_band,
    COUNT(DISTINCT l.loan_id) AS total_loans,
    COUNT(d.loan_id) AS defaulted_loans,
    ROUND(COUNT(d.loan_id) * 100.0 / COUNT(DISTINCT l.loan_id),
            2) AS default_rate_pct
FROM
    loans l
        JOIN
    customers c ON l.customer_id = c.customer_id
        LEFT JOIN
    defaults d ON l.loan_id = d.loan_id
GROUP BY income_band
ORDER BY default_rate_pct DESC;

-- Yes; Low Income = Higher default rates. (making around 9.30% !)
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1.4 Are some loan products inherently riskier?
SELECT 
    l.loan_type,
    COUNT(DISTINCT l.loan_id) AS total_loans,
    COUNT(d.loan_id) AS defaulted_loans,
    ROUND(COUNT(d.loan_id) * 100.0 / COUNT(DISTINCT l.loan_id),
            2) AS default_rate_pct
FROM
    loans l
        LEFT JOIN
    defaults d ON l.loan_id = d.loan_id
GROUP BY l.loan_type
ORDER BY default_rate_pct DESC;

-- 'Auto' & 'Personal' loans are more prone to loan default. (making around 6% - 6.50%)
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1.5 Do larger loans default more?
SELECT 
    CASE
        WHEN loan_amount < 50000 THEN 'Small'
        WHEN loan_amount BETWEEN 50000 AND 150000 THEN 'Medium'
        ELSE 'Large'
    END AS loan_size_band,
    COUNT(*) AS total_loans,
    COUNT(d.loan_id) AS defaulted_loans,
    ROUND(COUNT(d.loan_id) * 100.0 / COUNT(*), 2) AS default_rate_pct
FROM
    loans l
        LEFT JOIN
    defaults d ON l.loan_id = d.loan_id
GROUP BY loan_size_band
ORDER BY default_rate_pct DESC;

-- Yes; Large size loans = Higher defaulted loans. (making around 1.5x of 'Medium loans' and 4.5x of 'Small Loans')
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1.6 Are longer-term loans riskier?
SELECT 
    loan_term_months,
    COUNT(*) AS total_loans,
    COUNT(d.loan_id) AS defaulted_loans,
    ROUND(COUNT(d.loan_id) * 100.0 / COUNT(*), 2) AS default_rate_pct
FROM
    loans l
        LEFT JOIN
    defaults d ON l.loan_id = d.loan_id
GROUP BY loan_term_months
ORDER BY loan_term_months;

-- Yes; Longer-term loans with more than 24 months are riskier, more prone to higher default rate.
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1.7 Is risk geographically concentrated?
SELECT 
    c.region,
    COUNT(DISTINCT l.loan_id) AS total_loans,
    COUNT(d.loan_id) AS defaulted_loans,
    ROUND(COUNT(d.loan_id) * 100.0 / COUNT(DISTINCT l.loan_id),
            2) AS default_rate_pct
FROM
    loans l
        JOIN
    customers c ON l.customer_id = c.customer_id
        LEFT JOIN
    defaults d ON l.loan_id = d.loan_id
GROUP BY c.region
ORDER BY default_rate_pct DESC;

-- Yes; 'NORTH' region is making almost 7.50% of default loans. (making around 1.5x of other regions)
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- ===============================================================================================================================================================================================
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ===============================================================================================================================================================================================