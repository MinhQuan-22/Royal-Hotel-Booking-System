# Task 1.3.5: NULL and Zero OldRate Filter Logic

## Filter Logic Flow

```
Rate Update Occurs
       |
       v
   IF UPDATE(Rate)?
       |
       +-- NO --> Exit (no processing)
       |
       +-- YES --> Continue
                    |
                    v
              Join inserted & deleted tables
                    |
                    v
              Apply WHERE filters:
                    |
                    +-- d.Rate IS NOT NULL?
                    |        |
                    |        +-- NO --> Skip row (no log entry)
                    |        |
                    |        +-- YES --> Continue
                    |                    |
                    +--------------------+
                    |
                    v
              d.Rate > 0?
                    |
                    +-- NO --> Skip row (no log entry)
                    |          [Handles: zero, negative]
                    |
                    +-- YES --> Continue
                                |
                                v
                          Calculate: ABS(((i.Rate - d.Rate) / d.Rate) * 100)
                                |
                                v
                          Result > 50?
                                |
                                +-- NO --> Skip row (no log entry)
                                |
                                +-- YES --> INSERT into RoomRateChangeLog
                                            [Log entry created]
```

## Filter Evaluation Order

SQL Server optimizes the WHERE clause evaluation, but logically:

1. **First Filter**: `d.Rate IS NOT NULL`
   - **Purpose**: Prevent NULL arithmetic
   - **Blocks**: NULL old rates
   - **Result**: NULL values never reach division operation

2. **Second Filter**: `d.Rate > 0`
   - **Purpose**: Prevent division by zero
   - **Blocks**: Zero and negative old rates
   - **Result**: Zero/negative values never reach division operation

3. **Third Filter**: `ABS(((i.Rate - d.Rate) / d.Rate) * 100) > 50`
   - **Purpose**: Only log significant changes
   - **Blocks**: Changes ≤ 50%
   - **Result**: Only changes > 50% are logged

## Truth Table

| Old Rate (d.Rate) | New Rate (i.Rate) | NULL Filter | Zero Filter | Calc Possible? | Change > 50%?  | Log Entry? |
| ----------------- | ----------------- | ----------- | ----------- | -------------- | -------------- | ---------- |
| NULL              | 100               | ❌ FAIL     | N/A         | ❌ NO          | N/A            | ❌ NO      |
| 0                 | 100               | ✅ PASS     | ❌ FAIL     | ❌ NO          | N/A            | ❌ NO      |
| -50               | 100               | ✅ PASS     | ❌ FAIL     | ❌ NO          | N/A            | ❌ NO      |
| 0.01              | 100               | ✅ PASS     | ✅ PASS     | ✅ YES         | ✅ YES         | ✅ YES     |
| 100               | 130               | ✅ PASS     | ✅ PASS     | ✅ YES         | ❌ NO (+30%)   | ❌ NO      |
| 100               | 200               | ✅ PASS     | ✅ PASS     | ✅ YES         | ✅ YES (+100%) | ✅ YES     |
| 100               | 40                | ✅ PASS     | ✅ PASS     | ✅ YES         | ✅ YES (-60%)  | ✅ YES     |

## Code Snippet

```sql
WHERE
    -- Filter 1: Prevent NULL arithmetic
    d.Rate IS NOT NULL

    -- Filter 2: Prevent division by zero (and negative rates)
    AND d.Rate > 0

    -- Filter 3: Only log significant changes (> 50%)
    AND ABS(((i.Rate - d.Rate) / d.Rate) * 100) > 50;
```

## Why This Order Matters

### Scenario 1: NULL Old Rate

```sql
-- Without NULL filter:
((100 - NULL) / NULL) * 100
= (NULL / NULL) * 100
= NULL * 100
= NULL
-- Result: NULL (not an error, but incorrect - would insert NULL ChangePercent)

-- With NULL filter:
d.Rate IS NOT NULL  -- Evaluates to FALSE
-- Result: Row skipped, no calculation attempted
```

### Scenario 2: Zero Old Rate

```sql
-- Without zero filter:
((100 - 0) / 0) * 100
= (100 / 0) * 100
= ERROR: Divide by zero error encountered
-- Result: Trigger fails, UPDATE operation fails

-- With zero filter:
d.Rate > 0  -- Evaluates to FALSE
-- Result: Row skipped, no calculation attempted
```

### Scenario 3: Valid Old Rate

```sql
-- With both filters passing:
d.Rate IS NOT NULL  -- TRUE (e.g., 100)
AND d.Rate > 0      -- TRUE (100 > 0)
-- Calculation proceeds safely:
((200 - 100) / 100) * 100
= (100 / 100) * 100
= 1 * 100
= 100
-- Then check: ABS(100) > 50  -- TRUE
-- Result: Log entry created with ChangePercent = 100
```

## Multi-Row Update Behavior

When updating multiple rows in a single UPDATE statement:

```sql
UPDATE Rooms SET Rate = NewRate WHERE Id IN (1, 2, 3, 4);
```

The trigger processes each row independently:

| Room ID | Old Rate | New Rate | Filter Result                 | Action |
| ------- | -------- | -------- | ----------------------------- | ------ |
| 1       | NULL     | 200      | NULL filter fails             | Skip   |
| 2       | 0        | 200      | Zero filter fails             | Skip   |
| 3       | 100      | 200      | All filters pass, +100% > 50% | Log    |
| 4       | 50       | 60       | All filters pass, +20% ≤ 50%  | Skip   |

**Result**: Only Room 3 creates an audit log entry.

## Performance Considerations

### Filter Efficiency

1. **Short-circuit evaluation**: SQL Server may stop evaluating once a condition fails
2. **Index usage**: Filters on `d.Rate` can use indexes if available
3. **Minimal overhead**: Simple comparisons (IS NOT NULL, > 0) are very fast

### Calculation Avoidance

By filtering before calculation:

- ✅ Prevents unnecessary division operations
- ✅ Reduces CPU usage for filtered rows
- ✅ Avoids error handling overhead

## Compliance Matrix

| Requirement                | Implementation              | Status         |
| -------------------------- | --------------------------- | -------------- |
| Prevent division by zero   | `d.Rate > 0` filter         | ✅ IMPLEMENTED |
| Handle NULL old rates      | `d.Rate IS NOT NULL` filter | ✅ IMPLEMENTED |
| No log for zero old rate   | Zero filter prevents insert | ✅ IMPLEMENTED |
| No log for NULL old rate   | NULL filter prevents insert | ✅ IMPLEMENTED |
| No calculation for zero    | Filters before calculation  | ✅ IMPLEMENTED |
| No calculation for NULL    | Filters before calculation  | ✅ IMPLEMENTED |
| No errors on invalid rates | Filters prevent errors      | ✅ IMPLEMENTED |

## Testing Validation

All test scenarios in `test_task_1.3.5_null_zero_handling.sql` validate:

- ✅ NULL old rate → No log entry
- ✅ Zero old rate → No log entry
- ✅ Negative old rate → No log entry (bonus)
- ✅ Very small positive rate → Log entry (edge case)
- ✅ Multi-row mixed scenarios → Selective logging
- ✅ No errors during execution

## Conclusion

The filter logic correctly implements Requirement 2, AC 6:

> WHEN OLD.Rate is zero or NULL, THE Rate_Audit_Trigger SHALL NOT attempt to calculate ChangePercent and SHALL NOT insert a log record

**Implementation**: ✅ VERIFIED  
**Testing**: ✅ COMPREHENSIVE  
**Compliance**: ✅ SATISFIED
