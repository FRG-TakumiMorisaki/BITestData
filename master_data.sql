-- master_data.sql
-- SQLite schema and seed data for Department, User, and Product master tables.

PRAGMA foreign_keys = ON;

-- Department: 1 record = 1 team
CREATE TABLE IF NOT EXISTS Department (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  division_name TEXT NOT NULL,
  department_type TEXT NOT NULL CHECK (department_type IN ('Sales', 'Support'))
);

-- User: includes sales and support members
CREATE TABLE IF NOT EXISTS User (
  id INTEGER PRIMARY KEY,
  department_id INTEGER NOT NULL REFERENCES Department(id),
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL CHECK (role IN ('SalesRep', 'SalesManager', 'SupportEngineer', 'SupportLead')),
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Product: software catalog including subscription and service offerings
CREATE TABLE IF NOT EXISTS Product (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('Core', 'Addon', 'Service')),
  unit_price REAL NOT NULL,
  is_subscription INTEGER NOT NULL DEFAULT 1,
  default_term_months INTEGER,
  is_active INTEGER NOT NULL DEFAULT 1
);

-- ========================
-- Department seed data
-- ========================
INSERT INTO Department (id, name, division_name, department_type) VALUES
  (1, '東日本製造・流通営業1課', '営業第1ディビジョン（東日本）', 'Sales'),
  (2, '東日本製造・流通営業2課', '営業第1ディビジョン（東日本）', 'Sales'),
  (3, '西日本パートナー営業課', '営業第1ディビジョン（東日本）', 'Sales'),
  (4, '公共・金融営業第1課', '営業第2ディビジョン（公共・金融）', 'Sales'),
  (5, '公共・金融営業第2課', '営業第2ディビジョン（公共・金融）', 'Sales'),
  (6, 'グローバルアカウント第1課', 'エンタープライズ営業本部', 'Sales'),
  (7, 'グローバルアカウント第2課', 'エンタープライズ営業本部', 'Sales'),
  (8, 'オンボーディング支援チーム', 'カスタマーサポート', 'Support'),
  (9, '運用サポートチーム', 'カスタマーサポート', 'Support');

-- ========================
-- User seed data
-- Each sales team has 5-7 members with one manager; support teams have 1 lead + 4 engineers
-- ========================
INSERT INTO User (id, department_id, name, email, role, is_active) VALUES
  -- 東日本製造・流通営業1課 (6名)
  (1, 1, '田中 直樹', 'naoki.tanaka@example.com', 'SalesManager', 1),
  (2, 1, '佐藤 美咲', 'misaki.sato@example.com', 'SalesRep', 1),
  (3, 1, '中村 涼', 'ryo.nakamura@example.com', 'SalesRep', 1),
  (4, 1, '山本 彩香', 'ayaka.yamamoto@example.com', 'SalesRep', 1),
  (5, 1, '渡辺 誠', 'makoto.watanabe@example.com', 'SalesRep', 1),
  (6, 1, '加藤 佳奈', 'kana.kato@example.com', 'SalesRep', 1),
  -- 東日本製造・流通営業2課 (5名)
  (7, 2, '小林 拓海', 'takumi.kobayashi@example.com', 'SalesManager', 1),
  (8, 2, '石井 里奈', 'rina.ishii@example.com', 'SalesRep', 1),
  (9, 2, '松本 優', 'yu.matsumoto@example.com', 'SalesRep', 1),
  (10, 2, '山田 陽菜', 'hina.yamada@example.com', 'SalesRep', 1),
  (11, 2, '福田 慎吾', 'shingo.fukuda@example.com', 'SalesRep', 1),
  -- 西日本パートナー営業課 (5名)
  (12, 3, '高橋 俊介', 'shunsuke.takahashi@example.com', 'SalesManager', 1),
  (13, 3, '森田 悠真', 'yuma.morita@example.com', 'SalesRep', 1),
  (14, 3, '伊藤 心結', 'miyu.ito@example.com', 'SalesRep', 1),
  (15, 3, '大野 智也', 'tomoya.ohno@example.com', 'SalesRep', 1),
  (16, 3, '岡田 怜奈', 'rena.okada@example.com', 'SalesRep', 1),
  -- 公共・金融営業第1課 (6名)
  (17, 4, '村上 航', 'wataru.murakami@example.com', 'SalesManager', 1),
  (18, 4, '菊地 里帆', 'riho.kikuchi@example.com', 'SalesRep', 1),
  (19, 4, '林 智樹', 'tomoki.hayashi@example.com', 'SalesRep', 1),
  (20, 4, '阿部 琴葉', 'kotoha.abe@example.com', 'SalesRep', 1),
  (21, 4, '吉田 大輝', 'daiki.yoshida@example.com', 'SalesRep', 1),
  (22, 4, '原田 千夏', 'chinatsu.harada@example.com', 'SalesRep', 1),
  -- 公共・金融営業第2課 (5名)
  (23, 5, '平野 慎太郎', 'shintaro.hirano@example.com', 'SalesManager', 1),
  (24, 5, '長谷川 楓', 'kaede.hasegawa@example.com', 'SalesRep', 1),
  (25, 5, '杉本 圭', 'kei.sugimoto@example.com', 'SalesRep', 1),
  (26, 5, '島田 紗英', 'sae.shimada@example.com', 'SalesRep', 1),
  (27, 5, '内田 翔太', 'shota.uchida@example.com', 'SalesRep', 1),
  -- グローバルアカウント第1課 (6名)
  (28, 6, '藤田 美月', 'mizuki.fujita@example.com', 'SalesManager', 1),
  (29, 6, '山崎 海斗', 'kaito.yamazaki@example.com', 'SalesRep', 1),
  (30, 6, '竹内 優奈', 'yuna.takeuchi@example.com', 'SalesRep', 1),
  (31, 6, '三浦 翔', 'sho.miura@example.com', 'SalesRep', 1),
  (32, 6, '関根 純', 'jun.sekine@example.com', 'SalesRep', 1),
  (33, 6, '本田 美佳', 'mika.honda@example.com', 'SalesRep', 1),
  -- グローバルアカウント第2課 (5名)
  (34, 7, '大西 亮', 'ryo.onishi@example.com', 'SalesManager', 1),
  (35, 7, '堀内 里佳', 'rika.horiuchi@example.com', 'SalesRep', 1),
  (36, 7, '川上 蒼', 'ao.kawakami@example.com', 'SalesRep', 1),
  (37, 7, '岸本 梨花', 'rinka.kishimoto@example.com', 'SalesRep', 1),
  (38, 7, '上田 勇人', 'hayato.ueda@example.com', 'SalesRep', 1),
  -- オンボーディング支援チーム (5名)
  (39, 8, '柴田 裕介', 'yusuke.shibata@example.com', 'SupportLead', 1),
  (40, 8, '宮本 菜摘', 'natsumi.miyamoto@example.com', 'SupportEngineer', 1),
  (41, 8, '石川 大地', 'daichi.ishikawa@example.com', 'SupportEngineer', 1),
  (42, 8, '藤本 香織', 'kaori.fujimoto@example.com', 'SupportEngineer', 1),
  (43, 8, '黒田 智美', 'tomomi.kuroda@example.com', 'SupportEngineer', 1),
  -- 運用サポートチーム (5名)
  (44, 9, '植田 慎平', 'shimpei.ueda@example.com', 'SupportLead', 1),
  (45, 9, '青木 里緒', 'rio.aoki@example.com', 'SupportEngineer', 1),
  (46, 9, '中川 啓太', 'keita.nakagawa@example.com', 'SupportEngineer', 1),
  (47, 9, '永田 愛美', 'manami.nagata@example.com', 'SupportEngineer', 1),
  (48, 9, '松井 達也', 'tatsuya.matsui@example.com', 'SupportEngineer', 1);

-- ========================
-- Product seed data
-- ========================
INSERT INTO Product (id, name, category, unit_price, is_subscription, default_term_months, is_active) VALUES
  (1, 'NexView Platform', 'Core', 480000, 1, 12, 1),
  (2, 'NexView Analytics Plus', 'Addon', 180000, 1, 12, 1),
  (3, 'Workflow Automation Pack', 'Addon', 120000, 1, 12, 1),
  (4, 'Security & Compliance Suite', 'Addon', 220000, 1, 12, 1),
  (5, 'Enterprise Support Plan', 'Service', 90000, 1, 12, 1),
  (6, 'Implementation Kickstart', 'Service', 350000, 0, NULL, 1),
  (7, 'Data Migration Service', 'Service', 280000, 0, NULL, 1),
  (8, 'Developer Sandbox', 'Addon', 60000, 1, 12, 1),
  (9, 'AI Assistant Module', 'Addon', 150000, 1, 12, 1),
  (10, 'IoT Integration Gateway', 'Addon', 200000, 1, 12, 1);
