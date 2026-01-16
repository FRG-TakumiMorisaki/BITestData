-- opportunity_snapshot_fy2024_2025.sql
-- Weekly-like OpportunitySnapshot data derived from existing Opportunity records.
PRAGMA foreign_keys = ON;

-- OpportunitySnapshot table for weekly rollup
CREATE TABLE IF NOT EXISTS OpportunitySnapshot (
  id INTEGER PRIMARY KEY,
  opportunity_id INTEGER NOT NULL REFERENCES Opportunity(id),
  stage TEXT NOT NULL,
  amount REAL NOT NULL,
  close_date TEXT NOT NULL,
  probability INTEGER NOT NULL,
  is_closed INTEGER NOT NULL DEFAULT 0,
  is_won INTEGER NOT NULL DEFAULT 0,
  snapshot_date TEXT NOT NULL,
  owner_user_id INTEGER NOT NULL REFERENCES User(id)
);

CREATE INDEX IF NOT EXISTS idx_snapshot_opportunity ON OpportunitySnapshot(opportunity_id);
CREATE INDEX IF NOT EXISTS idx_snapshot_owner ON OpportunitySnapshot(owner_user_id);
CREATE INDEX IF NOT EXISTS idx_snapshot_date ON OpportunitySnapshot(snapshot_date);

--
-- Snapshot generation policy
-- - 再起CTEではなく、商談ごとに手作業のようなばらつきを持たせてシーケンスを分岐させる。
-- - 変更が発生した週のみスナップショットを作成し、その他の週は分析時に JOIN で補完できるようにする。
-- - Won: 4〜5枚、Lost: 2〜3枚、Open: 2〜4枚の範囲でランダムに決定する。
-- - 日付は created_date 起点で 6〜10 日刻みにランダム加算し、最終は close_date（未クローズは予定 close_date）を上限にする。
--
INSERT INTO OpportunitySnapshot (
  opportunity_id,
  stage,
  amount,
  close_date,
  probability,
  is_closed,
  is_won,
  snapshot_date,
  owner_user_id
)
WITH base AS (
  SELECT
    o.id AS opportunity_id,
    o.owner_user_id,
    o.type,
    o.stage AS current_stage,
    o.amount,
    o.close_date,
    o.created_date,
    o.probability AS current_probability,
    o.is_closed,
    o.is_won,
    abs(random()) % 100 AS seed,
    CASE
      WHEN o.is_won = 1 THEN 4 + (abs(random()) % 2)
      WHEN o.is_closed = 1 THEN 2 + (abs(random()) % 2)
      ELSE 2 + (abs(random()) % 3)
    END AS max_seq
  FROM Opportunity o
),
seq AS (
  SELECT 1 AS seq UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
),
plan AS (
  SELECT
    b.opportunity_id,
    b.owner_user_id,
    b.type,
    b.current_stage,
    b.amount,
    b.close_date,
    b.created_date,
    b.current_probability,
    b.is_closed,
    b.is_won,
    b.max_seq,
    b.seed,
    s.seq,
    CASE
      WHEN b.is_won = 1 THEN CASE
        WHEN s.seq = 1 THEN CASE WHEN b.type = 'New' THEN 'Prospecting' ELSE 'Upcoming Renewal' END
        WHEN s.seq = 2 THEN CASE
          WHEN b.type = 'New' THEN CASE WHEN b.seed % 3 = 0 THEN 'Qualification' ELSE 'Needs Analysis' END
          ELSE 'Renewal Negotiation'
        END
        WHEN s.seq = 3 THEN CASE
          WHEN b.type = 'New' THEN CASE WHEN b.seed % 2 = 0 THEN 'Proposal' ELSE 'Negotiation' END
          ELSE CASE WHEN b.seed % 2 = 0 THEN 'Renewal Negotiation' ELSE 'Upcoming Renewal' END
        END
        WHEN s.seq = 4 AND b.max_seq > 4 THEN CASE WHEN b.type = 'New' THEN 'Verbal Commit' ELSE 'Renewal Negotiation' END
        ELSE 'Closed Won'
      END
      WHEN b.is_closed = 1 THEN CASE
        WHEN s.seq = 1 THEN CASE WHEN b.type = 'New' THEN 'Prospecting' ELSE 'Upcoming Renewal' END
        WHEN s.seq = 2 THEN CASE
          WHEN b.type = 'New' THEN CASE WHEN b.seed % 2 = 0 THEN 'Needs Analysis' ELSE 'Proposal' END
          ELSE 'Renewal Negotiation'
        END
        ELSE 'Closed Lost'
      END
      ELSE CASE
        WHEN s.seq = 1 THEN CASE
          WHEN b.type = 'New' THEN CASE b.current_stage
            WHEN 'Prospecting' THEN 'Prospecting'
            WHEN 'Qualification' THEN 'Prospecting'
            WHEN 'Needs Analysis' THEN 'Qualification'
            WHEN 'Proposal' THEN CASE WHEN b.seed % 2 = 0 THEN 'Qualification' ELSE 'Needs Analysis' END
            WHEN 'Negotiation' THEN CASE WHEN b.seed % 3 = 0 THEN 'Needs Analysis' ELSE 'Proposal' END
            WHEN 'Verbal Commit' THEN CASE WHEN b.seed % 2 = 0 THEN 'Proposal' ELSE 'Negotiation' END
            ELSE 'Prospecting'
          END
          ELSE CASE b.current_stage
            WHEN 'Upcoming Renewal' THEN 'Upcoming Renewal'
            ELSE 'Upcoming Renewal'
          END
        END
        WHEN s.seq = 2 THEN CASE
          WHEN b.type = 'New' THEN CASE b.current_stage
            WHEN 'Prospecting' THEN 'Qualification'
            WHEN 'Qualification' THEN 'Needs Analysis'
            WHEN 'Needs Analysis' THEN 'Proposal'
            WHEN 'Proposal' THEN CASE WHEN b.seed % 2 = 0 THEN 'Negotiation' ELSE 'Proposal' END
            WHEN 'Negotiation' THEN CASE WHEN b.seed % 3 = 0 THEN 'Proposal' ELSE 'Negotiation' END
            WHEN 'Verbal Commit' THEN 'Negotiation'
            ELSE b.current_stage
          END
          ELSE CASE
            WHEN b.current_stage = 'Renewal Negotiation' THEN 'Upcoming Renewal'
            ELSE 'Upcoming Renewal'
          END
        END
        WHEN s.seq = 3 THEN CASE
          WHEN b.type = 'New' THEN CASE
            WHEN b.current_stage IN ('Prospecting','Qualification') THEN 'Needs Analysis'
            WHEN b.current_stage = 'Needs Analysis' THEN 'Proposal'
            WHEN b.current_stage = 'Proposal' THEN 'Negotiation'
            WHEN b.current_stage = 'Negotiation' THEN 'Verbal Commit'
            WHEN b.current_stage = 'Verbal Commit' THEN 'Verbal Commit'
            ELSE b.current_stage
          END
          ELSE 'Renewal Negotiation'
        END
        ELSE b.current_stage
      END
    END AS stage_name
  FROM base b
  JOIN seq s ON s.seq <= b.max_seq
),
stamped AS (
  SELECT
    p.opportunity_id,
    p.owner_user_id,
    p.type,
    p.stage_name,
    p.current_stage,
    p.amount,
    p.close_date,
    p.created_date,
    p.current_probability,
    p.is_closed,
    p.is_won,
    p.max_seq,
    p.seed,
    p.seq,
    CASE
      WHEN p.is_won = 1 THEN CASE p.seq
        WHEN 1 THEN 10
        WHEN 2 THEN CASE WHEN p.type = 'New' THEN 30 + (p.seed % 10) ELSE 65 + (p.seed % 5) END
        WHEN 3 THEN CASE WHEN p.type = 'New' THEN CASE WHEN p.stage_name = 'Proposal' THEN 45 + (p.seed % 15) ELSE 65 + (p.seed % 15) END ELSE 80 END
        WHEN 4 THEN CASE WHEN p.stage_name = 'Verbal Commit' THEN 85 + (p.seed % 10) ELSE 100 END
        ELSE 100
      END
      WHEN p.is_closed = 1 THEN CASE p.seq
        WHEN 1 THEN CASE WHEN p.type = 'New' THEN 10 ELSE 45 + (p.seed % 10) END
        WHEN 2 THEN CASE WHEN p.type = 'New' THEN CASE WHEN p.stage_name = 'Proposal' THEN 40 + (p.seed % 15) ELSE 60 + (p.seed % 15) END ELSE 75 + (p.seed % 10) END
        ELSE 0
      END
      ELSE CASE p.seq
        WHEN 1 THEN CASE WHEN p.type = 'New' THEN 10 ELSE 50 + (p.seed % 10) END
        WHEN 2 THEN CASE
          WHEN p.type = 'New' THEN CASE p.current_stage
            WHEN 'Qualification' THEN 20 + (p.seed % 10)
            WHEN 'Needs Analysis' THEN 35 + (p.seed % 10)
            WHEN 'Proposal' THEN 50 + (p.seed % 10)
            WHEN 'Negotiation' THEN 65 + (p.seed % 15)
            WHEN 'Verbal Commit' THEN 85 + (p.seed % 10)
            ELSE p.current_probability
          END
          ELSE CASE p.current_stage WHEN 'Renewal Negotiation' THEN 70 + (p.seed % 15) ELSE 55 + (p.seed % 10) END
        END
        WHEN 3 THEN CASE
          WHEN p.type = 'New' THEN CASE
            WHEN p.stage_name = 'Verbal Commit' THEN 90 + (p.seed % 5)
            ELSE 60 + (p.seed % 20)
          END
          ELSE 70 + (p.seed % 15)
        END
        ELSE p.current_probability
      END
    END AS probability,
    CASE
      WHEN p.seq = p.max_seq THEN p.close_date
      ELSE date(p.created_date, printf('+%d days',
        CASE
          WHEN p.seq = 1 THEN 0
          WHEN p.seq = 2 THEN 6 + (abs(random()) % 5)
          WHEN p.seq = 3 THEN 12 + (abs(random()) % 8)
          WHEN p.seq = 4 THEN 20 + (abs(random()) % 10)
          ELSE 27 + (abs(random()) % 10)
        END))
    END AS snapshot_date
  FROM plan p
)
SELECT
  opportunity_id,
  stage_name AS stage,
  amount,
  close_date,
  probability,
  CASE WHEN stage_name LIKE 'Closed%' THEN 1 ELSE 0 END AS is_closed,
  CASE WHEN stage_name = 'Closed Won' THEN 1 ELSE 0 END AS is_won,
  CASE
    WHEN date(snapshot_date) > date(close_date) THEN close_date
    ELSE snapshot_date
  END AS snapshot_date,
  owner_user_id
FROM stamped
ORDER BY opportunity_id, snapshot_date;
