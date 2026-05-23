-- ============================================================
-- AN CUONG INT. — SUPABASE DATABASE SCHEMA
-- Chạy toàn bộ file này trong Supabase SQL Editor
-- ============================================================

-- ============================================================
-- 1. ENABLE UUID & AUTH EXTENSIONS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 2. BẢNG SẢN PHẨM (products)
-- ============================================================
CREATE TABLE IF NOT EXISTS products (
  id           SERIAL PRIMARY KEY,
  name         TEXT NOT NULL,
  category     TEXT NOT NULL CHECK (category IN ('sofa','ban','ghe','giuong','tu','den')),
  price        BIGINT NOT NULL CHECK (price > 0),
  badge        TEXT,
  img          TEXT NOT NULL,
  cat_label    TEXT NOT NULL,
  description  TEXT,
  in_stock     BOOLEAN DEFAULT TRUE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 3. BẢNG DỰ ÁN (projects)
-- ============================================================
CREATE TABLE IF NOT EXISTS projects (
  id         SERIAL PRIMARY KEY,
  name       TEXT NOT NULL,
  location   TEXT NOT NULL,
  area       TEXT NOT NULL,
  type       TEXT CHECK (type IN ('biet-thu','penthouse','can-ho','nha-pho')),
  img        TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 4. BẢNG TIN TỨC (news)
-- ============================================================
CREATE TABLE IF NOT EXISTS news (
  id         SERIAL PRIMARY KEY,
  cat        TEXT NOT NULL,
  date       TEXT NOT NULL,
  title      TEXT NOT NULL,
  excerpt    TEXT NOT NULL,
  img        TEXT NOT NULL,
  featured   BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 5. BẢNG GIỎ HÀNG (cart_items)
-- ============================================================
CREATE TABLE IF NOT EXISTS cart_items (
  id         SERIAL PRIMARY KEY,
  session_id TEXT NOT NULL,
  product_id INT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  qty        INT NOT NULL DEFAULT 1 CHECK (qty > 0),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (session_id, product_id)
);

-- ============================================================
-- 6. BẢNG LIÊN HỆ / TƯ VẤN (contact_requests)
-- ============================================================
CREATE TABLE IF NOT EXISTS contact_requests (
  id         SERIAL PRIMARY KEY,
  full_name  TEXT NOT NULL,
  phone      TEXT NOT NULL,
  email      TEXT NOT NULL,
  subject    TEXT,
  message    TEXT NOT NULL,
  status     TEXT DEFAULT 'pending' CHECK (status IN ('pending','processing','done')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 7. BẢNG ĐƠN HÀNG (orders)
-- ============================================================
CREATE TABLE IF NOT EXISTS orders (
  id              SERIAL PRIMARY KEY,
  order_code      TEXT UNIQUE NOT NULL DEFAULT ('AC' || TO_CHAR(NOW(),'YYYY') || LPAD(nextval('orders_seq')::TEXT, 5, '0')),
  session_id      TEXT,
  full_name       TEXT NOT NULL,
  phone           TEXT NOT NULL,
  email           TEXT NOT NULL,
  address         TEXT NOT NULL,
  city            TEXT,
  district        TEXT,
  note            TEXT,
  payment_method  TEXT DEFAULT 'bank_transfer'
                  CHECK (payment_method IN ('cod','bank_transfer','vnpay','momo','zalopay')),
  total_amount    BIGINT NOT NULL,
  status          TEXT DEFAULT 'pending'
                  CHECK (status IN ('pending','confirmed','shipping','delivered','cancelled')),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE SEQUENCE IF NOT EXISTS orders_seq START 1;

-- ============================================================
-- 8. BẢNG CHI TIẾT ĐƠN HÀNG (order_items)
-- ============================================================
CREATE TABLE IF NOT EXISTS order_items (
  id         SERIAL PRIMARY KEY,
  order_id   INT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id INT NOT NULL REFERENCES products(id),
  name       TEXT NOT NULL,
  price      BIGINT NOT NULL,
  qty        INT NOT NULL DEFAULT 1,
  img        TEXT
);

-- ============================================================
-- 9. ROW LEVEL SECURITY (RLS)
-- ============================================================

-- products: ai cũng đọc được
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "products_public_read"
  ON products FOR SELECT USING (TRUE);

-- projects: public read
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "projects_public_read"
  ON projects FOR SELECT USING (TRUE);

-- news: public read
ALTER TABLE news ENABLE ROW LEVEL SECURITY;
CREATE POLICY "news_public_read"
  ON news FOR SELECT USING (TRUE);

-- cart_items: chỉ đọc/ghi theo session_id
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "cart_own_session"
  ON cart_items FOR ALL
  USING (TRUE)
  WITH CHECK (TRUE);
-- Ghi chú: Với app thật, thay TRUE bằng session_id = current_setting('app.session_id')

-- contact_requests: ai cũng INSERT được, không đọc được
ALTER TABLE contact_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "contact_insert_only"
  ON contact_requests FOR INSERT WITH CHECK (TRUE);

-- orders & order_items: INSERT được, đọc theo session
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "orders_insert"
  ON orders FOR INSERT WITH CHECK (TRUE);
CREATE POLICY "orders_read_own"
  ON orders FOR SELECT USING (TRUE);

ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "order_items_insert"
  ON order_items FOR INSERT WITH CHECK (TRUE);
CREATE POLICY "order_items_read"
  ON order_items FOR SELECT USING (TRUE);

-- ============================================================
-- 10. DỮ LIỆU MẪU — SẢN PHẨM
-- ============================================================
INSERT INTO products (name, category, price, badge, img, cat_label, description) VALUES
('Sofa Modular Elegance',        'sofa',   35000000, 'Mới',     'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=500',   'Sofa',          'Sofa module thiết kế hiện đại, dễ dàng tùy chỉnh cấu hình.'),
('Ghế ăn gỗ Sồi đệm da',        'ghe',     4500000, NULL,      'https://images.unsplash.com/photo-1567538096630-e0c55bd6374c?w=500', 'Ghế ăn',        'Gỗ sồi tự nhiên kết hợp đệm da cao cấp.'),
('Bàn trà tròn Minimalist',      'ban',     8200000, NULL,      'https://images.unsplash.com/photo-1506439773649-6e0eb8cfb237?w=500', 'Bàn trà',       'Thiết kế tối giản, mặt kính cường lực chân thép mạ vàng.'),
('Giường bọc nỉ cao cấp',        'giuong', 22000000, 'Bán chạy','https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=500', 'Giường ngủ',    'Khung gỗ sồi, bọc nỉ nhung Bỉ cao cấp.'),
('Tủ áo gỗ Óc chó 4 cánh',      'tu',     28500000, NULL,      'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',   'Tủ & Kệ',       'Gỗ óc chó nguyên khối, 4 cánh mở rộng 2.4m.'),
('Bàn làm việc Executive',       'ban',    15800000, NULL,      'https://images.unsplash.com/photo-1593642632559-0c6d3fc62b89?w=500', 'Bàn làm việc',  'Mặt bàn da Ý, chân thép không gỉ.'),
('Ghế thư giãn Lounge Chair',    'ghe',    12000000, NULL,      'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=500', 'Ghế thư giãn',  'Ghế thư giãn phong cách Mid-Century Modern.'),
('Đèn chùm thả trần Luxury',     'den',     6500000, NULL,      'https://images.unsplash.com/photo-1524484485831-a92ffc0de03f?w=500', 'Đèn trang trí', 'Đèn thả trần 36 bóng LED, khung đồng mạ vàng.'),
('Kệ tivi gỗ nguyên khối',       'tu',     18200000, NULL,      'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=500',   'Tủ & Kệ',       'Kệ tivi gỗ óc chó, tích hợp ray âm tường.'),
('Sofa Da Bò Ý Milano 3',        'sofa',   85000000, NULL,      'https://images.unsplash.com/photo-1583845112203-29329902332e?w=500', 'Sofa',          'Bọc da bò Italy full-aniline, 3 chỗ ngồi.'),
('Sofa Góc Modular',             'sofa',   62500000, NULL,      'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?w=500', 'Sofa',          'Sofa góc L linh hoạt, nệm lông vũ cao cấp.'),
('Bàn Ăn Gỗ Óc Chó 8 Chỗ',      'ban',    45000000, 'Mới',     'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=500', 'Bàn ăn',        'Mặt bàn gỗ óc chó nguyên tấm, 8 chỗ ngồi.');

-- ============================================================
-- 11. DỮ LIỆU MẪU — DỰ ÁN
-- ============================================================
INSERT INTO projects (name, location, area, type, img) VALUES
('Vinhomes Golden River Penthouse', 'TP. Hồ Chí Minh', '450m²', 'penthouse',  'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=600'),
('Chateau Villa Phú Mỹ Hưng',       'TP. Hồ Chí Minh', '600m²', 'biet-thu',   'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=400'),
('Lakeview City Villa',             'TP. Hồ Chí Minh', '280m²', 'biet-thu',   'https://images.unsplash.com/photo-1560185007-cde436f6a4d0?w=400'),
('The Nassim Thảo Điền',            'TP. Hồ Chí Minh', '120m²', 'can-ho',     'https://images.unsplash.com/photo-1615529328331-f8917597711f?w=600'),
('Metropolis Apartment',            'Hà Nội',           '140m²', 'can-ho',     'https://images.unsplash.com/photo-1618220048045-10a6dbdf83e0?w=400'),
('Serenity Sky Villas',             'TP. Hồ Chí Minh', '210m²', 'penthouse',  'https://images.unsplash.com/photo-1618220179428-22790b461013?w=400'),
('Ecopark Grand Villa',             'Hưng Yên',         '320m²', 'biet-thu',   'https://images.unsplash.com/photo-1600210492493-0946911123ea?w=600'),
('Waterina Suites',                 'TP. Hồ Chí Minh', '160m²', 'can-ho',     'https://images.unsplash.com/photo-1616047006789-b7af5afb8c20?w=400'),
('Sun Grand City',                  'Hà Nội',           '180m²', 'nha-pho',    'https://images.unsplash.com/photo-1604014237800-1c9102c219da?w=400');

-- ============================================================
-- 12. DỮ LIỆU MẪU — TIN TỨC
-- ============================================================
INSERT INTO news (cat, date, title, excerpt, img, featured) VALUES
('XU HƯỚNG',     '12 Tháng 10, 2025', 'Xu hướng thiết kế nội thất tối giản (Minimalism) lên ngôi năm 2025',                    'Phong cách tối giản không chỉ là một trào lưu nhất thời mà đã trở thành triết lý sống. Sự tinh giản trong đường nét kết hợp với vật liệu cao cấp mang lại không gian sống đẳng cấp và bình yên.', 'https://images.unsplash.com/photo-1583845112203-29329902332e?w=800', TRUE),
('MẸO TRANG TRÍ','03 Tháng 10, 2025', 'Cách chọn sofa hoàn hảo cho không gian phòng khách hiện đại',                           'Lựa chọn một chiếc sofa không chỉ dựa vào kiểu dáng mà còn phải phù hợp với tỷ lệ không gian và chất liệu vải để đảm bảo sự thoải mái tuyệt đối.',                                           'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=500', FALSE),
('KIẾN THỨC',    '28 Tháng 9, 2025',  'Gỗ óc chó (Walnut): Chất liệu vàng trong làng nội thất cao cấp',                        'Tìm hiểu lý do tại sao gỗ óc chó luôn đứng vững trong những đường vân độc đáo và màu sắc trầm ấm.',                                                                                         'https://images.unsplash.com/photo-1615529328331-f8917597711f?w=500', FALSE),
('SỰ KIỆN',      '15 Tháng 9, 2025',  'Khai trương Showroom Concept mới tại trung tâm Quận 1',                                  'Sự kiện ra mắt không gian trải nghiệm nội thất đẳng cấp quốc tế với diện tích hơn 1000m2.',                                                                                                'https://images.unsplash.com/photo-1618220179428-22790b461013?w=500', FALSE),
('XU HƯỚNG',     '02 Tháng 8, 2025',  'Bảng màu chủ đạo định hình phong cách thiết kế phòng ngủ 2025',                         'Từ những tông màu đất âm đến sắc xanh dịu nhẹ, khám phá những xu hướng màu sắc giúp biến phòng ngủ thành nơi tĩnh yên.',                                                               'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=500', FALSE),
('MẸO TRANG TRÍ','20 Tháng 8, 2025',  'Ánh sáng: Yếu tố quyết định sự sang trọng của không gian',                               'Nghệ thuật bố trí ánh sáng trong thiết kế nội thất không chỉ giúp tôn lên vẻ đẹp mà còn điều chỉnh cảm xúc trong từng khu vực sống.',                                                     'https://images.unsplash.com/photo-1560185007-cde436f6a4d0?w=500', FALSE),
('SỰ KIỆN',      '10 Tháng 8, 2025',  'Tổng hợp những điểm nhấn tại Triển lãm Nội thất Quốc tế Salone del Mobile',             'Cùng nhìn lại những bộ sưu tập ấn tượng và các xu hướng thiết kế sẽ định hình thị trường nội thất toàn cầu trong thời gian tới.',                                                       'https://images.unsplash.com/photo-1600210492493-0946911123ea?w=500', FALSE);

-- ============================================================
-- 13. INDEXES (tối ưu hiệu năng)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_products_category  ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_in_stock   ON products(in_stock);
CREATE INDEX IF NOT EXISTS idx_projects_type       ON projects(type);
CREATE INDEX IF NOT EXISTS idx_news_featured       ON news(featured);
CREATE INDEX IF NOT EXISTS idx_cart_session        ON cart_items(session_id);
CREATE INDEX IF NOT EXISTS idx_orders_session      ON orders(session_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order   ON order_items(order_id);

-- ============================================================
-- 14. HÀM TIỆN ÍCH
-- ============================================================

-- Lấy tổng giỏ hàng theo session
CREATE OR REPLACE FUNCTION get_cart_total(p_session_id TEXT)
RETURNS BIGINT AS $$
  SELECT COALESCE(SUM(c.qty * p.price), 0)
  FROM cart_items c
  JOIN products p ON p.id = c.product_id
  WHERE c.session_id = p_session_id;
$$ LANGUAGE sql STABLE;

-- Tạo đơn hàng từ giỏ hàng
CREATE OR REPLACE FUNCTION place_order(
  p_session_id    TEXT,
  p_full_name     TEXT,
  p_phone         TEXT,
  p_email         TEXT,
  p_address       TEXT,
  p_city          TEXT,
  p_district      TEXT,
  p_note          TEXT,
  p_payment       TEXT
) RETURNS INT AS $$
DECLARE
  v_order_id   INT;
  v_total      BIGINT;
BEGIN
  -- Tính tổng tiền
  SELECT get_cart_total(p_session_id) INTO v_total;
  IF v_total = 0 THEN RAISE EXCEPTION 'Giỏ hàng trống'; END IF;

  -- Tạo đơn hàng
  INSERT INTO orders (session_id, full_name, phone, email, address, city, district, note, payment_method, total_amount)
  VALUES (p_session_id, p_full_name, p_phone, p_email, p_address, p_city, p_district, p_note, p_payment, v_total)
  RETURNING id INTO v_order_id;

  -- Copy chi tiết từ giỏ hàng sang đơn hàng
  INSERT INTO order_items (order_id, product_id, name, price, qty, img)
  SELECT v_order_id, p.id, p.name, p.price, c.qty, p.img
  FROM cart_items c
  JOIN products p ON p.id = c.product_id
  WHERE c.session_id = p_session_id;

  -- Xóa giỏ hàng
  DELETE FROM cart_items WHERE session_id = p_session_id;

  RETURN v_order_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- XONG! Bước tiếp theo: Cập nhật HTML
-- ============================================================
-- Thay 2 dòng này trong file HTML với thông tin Supabase của bạn:
--   const SUPABASE_URL = 'https://YOUR_PROJECT_ID.supabase.co';
--   const SUPABASE_KEY = 'YOUR_ANON_PUBLIC_KEY';
-- Sau đó bỏ comment phần initSupabase() ở cuối script.
-- ============================================================
