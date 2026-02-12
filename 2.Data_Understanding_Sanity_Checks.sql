-- ===============================================================================================================================================================================================
--                                                -: DATA UNDERSTANDING & SANITY CHECKS :-
-- ===============================================================================================================================================================================================
-- Row Counts & Basic Validation :-

SELECT 
    'customers' AS table_name, COUNT(*) AS row_count
FROM
    customers 
UNION ALL SELECT 
    'credit_history', COUNT(*)
FROM
    credit_history 
UNION ALL SELECT 
    'loans', COUNT(*)
FROM
    loans 
UNION ALL SELECT 
    'repayments', COUNT(*)
FROM
    repayments 
UNION ALL SELECT 
    'defaults', COUNT(*)
FROM
    defaults;

-- Row Counts are - 'customers' = 500; 'credit_history' = 500; 'loans' = 800; 'repayments' = 29172; 'defaults' = 44
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Primary Key Uniqueness Checks :- 

SELECT 
    customer_id, COUNT(*)
FROM
    customers                                                       # Checks For Duplicate 'customer_id'
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT 
    repayment_id, COUNT(*)
FROM
    repayments                                                      # Checks For Duplicate 'repayment_id'
GROUP BY repayment_id
HAVING COUNT(*) > 1;

SELECT 
    loan_id, COUNT(*)
FROM
    loans                                                            # Checks For Duplicate 'loan_id'
GROUP BY loan_id
HAVING COUNT(*) > 1;

-- No Duplicate values.
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Foreign Key Coverage Checks :-

SELECT 
    COUNT(*) AS orphan_loans
FROM
    loans l
        LEFT JOIN                                                          # Check 'loans' without 'customers'
    customers c ON l.customer_id = c.customer_id
WHERE
    c.customer_id IS NULL;

SELECT 
    COUNT(*) AS orphan_repayments
FROM
    repayments r
        LEFT JOIN                                                           # Check 'repayments' without 'loans'
    loans l ON r.loan_id = l.loan_id
WHERE
    l.loan_id IS NULL;
    
SELECT 
    COUNT(*) AS orphan_defaults
FROM
    defaults d
        LEFT JOIN                                                     # Check 'defaults' without 'loans'
    loans l ON d.loan_id = l.loan_id
WHERE
    l.loan_id IS NULL;

-- No Orphan Records.
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Missing Value Checks :-

SELECT 
    SUM(customer_id IS NULL) AS missing_customer_id,
    SUM(age IS NULL) AS missing_age,
    SUM(annual_income IS NULL) AS missing_income,                        # Checking in 'customers'
    SUM(credit_score IS NULL) AS missing_credit_score
FROM
    customers;

SELECT 
    SUM(loan_amount IS NULL) AS missing_loan_amount,
    SUM(interest_rate IS NULL) AS missing_interest_rate,                 # Checking in 'loans'
    SUM(loan_term_months IS NULL) AS missing_term
FROM
    loans;

SELECT 
    SUM(amount_due IS NULL) AS missing_amount_due,
    SUM(amount_paid IS NULL) AS missing_amount_paid                       # Checking in 'repayments'
FROM 
    repayments;

-- No Missing Values.
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Date Range Validation :-

SELECT 
    MIN(approval_date) AS first_loan_date,
    MAX(approval_date) AS last_loan_date
FROM
    loans;

SELECT 
    MIN(due_date) AS first_due,
    MAX(payment_date) AS last_payment
FROM
    repayments;

SELECT 
    MIN(default_date) AS first_default,
    MAX(default_date) AS last_default
FROM
    defaults;

-- No Corrupt Records. (defaults are occurring after loan approval)
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Repayment Behavior Sanity Check :-

SELECT 
    COUNT(*) AS total_repayments,
    SUM(amount_paid < amount_due) AS partial_payments,
    SUM(payment_date > due_date) AS late_payments
FROM
    repayments;

-- This Confirms Behavioral Risk Signals Exist. (late_payments > partial_payments)
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Default Coverage Check :-

SELECT 
    COUNT(DISTINCT loan_id) AS total_loans,
    (SELECT 
            COUNT(*)
        FROM
            defaults) AS defaulted_loans,
    ROUND((SELECT 
                    COUNT(*)
                FROM
                    defaults) * 100.0 / COUNT(DISTINCT loan_id),
            2) AS default_rate_pct
FROM
    loans;

-- This Is The Baseline Default Rate Right Now. (default rate right now is 5.50%)
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- ===============================================================================================================================================================================================
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ===============================================================================================================================================================================================