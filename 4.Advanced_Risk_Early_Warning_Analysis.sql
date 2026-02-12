-- ===============================================================================================================================================================================================
--                                         -: Step 2. Advanced Risk Signals & Early Warning Analysis :-
-- ===============================================================================================================================================================================================
-- 2.1 Are customers who pay late more likely to default?
WITH repayment_flags AS (
    SELECT
        loan_id,
        MAX(payment_date > due_date) AS has_late_payment
    FROM repayments
    GROUP BY loan_id
)
SELECT
    r.has_late_payment,
    COUNT(*) AS total_loans,
    COUNT(d.loan_id) AS defaulted_loans,
    ROUND(COUNT(d.loan_id) * 100.0 / COUNT(*), 2) AS default_rate_pct
FROM repayment_flags r
LEFT JOIN defaults d ON r.loan_id = d.loan_id
GROUP BY r.has_late_payment;

-- Late payments are a strong early-warning indicator of default risk.
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2.2 Is paying less than due an early red flag?
WITH partial_payment AS (
    SELECT
        loan_id,
        MAX(amount_paid < amount_due) AS has_partial_payment
    FROM repayments
    GROUP BY loan_id
)
SELECT
    p.has_partial_payment,
    COUNT(*) AS total_loans,
    COUNT(d.loan_id) AS defaulted_loans,
    ROUND(COUNT(d.loan_id) * 100.0 / COUNT(*), 2) AS default_rate_pct
FROM partial_payment p
LEFT JOIN defaults d ON p.loan_id = d.loan_id
GROUP BY p.has_partial_payment;

-- Partial payments often appear months before default.
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2.3 Do prior defaults repeat?
SELECT 
    CASE
        WHEN ch.prior_defaults = 0 THEN 'No Prior Default'
        WHEN ch.prior_defaults = 1 THEN 'One Prior Default'
        ELSE 'Multiple Prior Defaults'
    END AS credit_history_group,
    COUNT(DISTINCT l.loan_id) AS total_loans,
    COUNT(d.loan_id) AS defaulted_loans,
    ROUND(COUNT(d.loan_id) * 100.0 / COUNT(DISTINCT l.loan_id),
            2) AS default_rate_pct
FROM
    loans l
        JOIN
    credit_history ch ON l.customer_id = ch.customer_id
        LEFT JOIN
    defaults d ON l.loan_id = d.loan_id
GROUP BY credit_history_group
ORDER BY default_rate_pct DESC;

-- Multiple Prior Defaults = Much Higher Future Default Risk.
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2.4 Which active loans should the risk team monitor today?
WITH risk_flags AS (
    SELECT
        l.loan_id,
        c.credit_score,
        ch.prior_defaults,
        MAX(r.payment_date > r.due_date) AS late_payment,
        MAX(r.amount_paid < r.amount_due) AS partial_payment
    FROM loans l
    JOIN customers c ON l.customer_id = c.customer_id
    JOIN credit_history ch ON l.customer_id = ch.customer_id
    JOIN repayments r ON l.loan_id = r.loan_id
    LEFT JOIN defaults d ON l.loan_id = d.loan_id
    WHERE d.loan_id IS NULL
    GROUP BY l.loan_id, c.credit_score, ch.prior_defaults
)
SELECT
    loan_id,
    credit_score,
    prior_defaults,
    late_payment,
    partial_payment
FROM risk_flags
WHERE
    credit_score < 650
    AND (late_payment = 1 OR partial_payment = 1 OR prior_defaults > 0)
ORDER BY credit_score;

-- This query simulates a real bank monitoring dashboard.
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2.5 Can we bucket loans into risk tiers?
WITH repayment_behavior AS (
    SELECT
        loan_id,
        MAX(payment_date > due_date) AS late_payment,
        MAX(amount_paid < amount_due) AS partial_payment
    FROM repayments
    GROUP BY loan_id
),
risk_score AS (
    SELECT
        l.loan_id,
        (
            CASE WHEN c.credit_score < 650 THEN 2 ELSE 0 END +
            CASE WHEN ch.prior_defaults > 0 THEN 2 ELSE 0 END +
            CASE WHEN rb.late_payment = 1 THEN 1 ELSE 0 END +
            CASE WHEN rb.partial_payment = 1 THEN 1 ELSE 0 END
        ) AS risk_points
    FROM loans l
    JOIN customers c ON l.customer_id = c.customer_id
    JOIN credit_history ch ON l.customer_id = ch.customer_id
    JOIN repayment_behavior rb ON l.loan_id = rb.loan_id
)
SELECT
    CASE
        WHEN risk_points >= 4 THEN 'High Risk'
        WHEN risk_points BETWEEN 2 AND 3 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_bucket,
    COUNT(*) AS loan_count
FROM risk_score
GROUP BY risk_bucket;

-- 'High Risk' loan count is higher than 'Medium Risk' (almost 2x). 
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- ===============================================================================================================================================================================================
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ===============================================================================================================================================================================================