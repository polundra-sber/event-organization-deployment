-- Создание таблиц

-- User
CREATE TABLE user_profile(
    login VARCHAR(20) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    surname VARCHAR(50) NOT NULL,
    comment_money_transfer TEXT
);

-- UserSecrets
CREATE TABLE user_secret (
    login VARCHAR(20) PRIMARY KEY,
    email VARCHAR(254) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    FOREIGN KEY (login) REFERENCES user_profile(login)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- EventStatus
CREATE TABLE event_status(
    event_status_id SERIAL PRIMARY KEY,
    event_status_name VARCHAR(16) NOT NULL
);

-- Event
CREATE TABLE event (
    event_id SERIAL PRIMARY KEY,
    event_name VARCHAR(100) NOT NULL,
    event_description TEXT,
    status_id INTEGER NOT NULL,
    location VARCHAR(100),
    event_date DATE NOT NULL,
    event_time TIME(0),
    chat_link TEXT,
    cost_allocated BOOL NOT NULL,
    FOREIGN KEY (status_id) REFERENCES event_status(event_status_id)
	ON DELETE NO ACTION ON UPDATE NO ACTION
);

-- Purchase
CREATE TABLE purchase (
    purchase_id SERIAL PRIMARY KEY,
    purchase_name VARCHAR(50) NOT NULL,
    purchase_description TEXT,
    cost DECIMAL(10, 2) NOT NULL,
    responsible_user VARCHAR(20),
    event_id INTEGER NOT NULL,
    FOREIGN KEY (responsible_user) REFERENCES user_profile(login)
	ON DELETE SET NULL ON UPDATE NO ACTION,
    FOREIGN KEY (event_id) REFERENCES event(event_id)
	ON DELETE NO ACTION ON UPDATE NO ACTION
);

-- Payer
CREATE TABLE payer (
    payer_id SERIAL PRIMARY KEY,
    purchase_id INTEGER NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    FOREIGN KEY (purchase_id) REFERENCES purchase(purchase_id)
	ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (user_id) REFERENCES user_profile
	(login)
	ON DELETE NO ACTION ON UPDATE NO ACTION
);

-- Receipt
CREATE TABLE receipt (
    receipt_id SERIAL PRIMARY KEY,
    file_path VARCHAR(255) NOT NULL
);

-- ReceiptList
CREATE TABLE receipt_list (
    receipt_list_id SERIAL PRIMARY KEY,
    purchase_id INTEGER NOT NULL,
    receipt_id INTEGER NOT NULL,
    FOREIGN KEY (purchase_id) REFERENCES purchase(purchase_id)
	ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (receipt_id) REFERENCES receipt(receipt_id)
	ON DELETE CASCADE ON UPDATE CASCADE
);

-- Stuff
CREATE TABLE stuff (
    stuff_id SERIAL PRIMARY KEY,
    stuff_name VARCHAR(50) NOT NULL,
    stuff_description TEXT,
    event_id INTEGER NOT NULL,
    responsible_user VARCHAR(20),
    FOREIGN KEY (event_id) REFERENCES event(event_id)
	ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (responsible_user) REFERENCES user_profile(login)
	ON DELETE SET NULL ON UPDATE NO ACTION
);

-- Role
CREATE TABLE role (
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(16) NOT NULL
);

-- EventUserList
CREATE TABLE event_user_list (
    event_user_list_id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL,
    user_id VARCHAR(20) NOT NULL,
    role_id INTEGER NOT NULL,
    FOREIGN KEY (event_id) REFERENCES event(event_id)
	ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (user_id) REFERENCES user_profile(login)
	ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (role_id) REFERENCES role(role_id)
	ON DELETE NO ACTION ON UPDATE NO ACTION
);

-- TaskStatus
CREATE TABLE task_status (
    task_status_id SERIAL PRIMARY KEY,
    task_status_name VARCHAR(16) NOT NULL
);

-- Task
CREATE TABLE task (
    task_id SERIAL PRIMARY KEY,
    task_name VARCHAR(50) NOT NULL,
    task_description TEXT,
    status_id INTEGER NOT NULL,
    event_id INTEGER NOT NULL,
    responsible_user VARCHAR(20),
    deadline_date DATE NOT NULL,
    deadline_time TIME(0),
    FOREIGN KEY (status_id) REFERENCES task_status(task_status_id)
	ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (event_id) REFERENCES event(event_id)
	ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (responsible_user) REFERENCES user_profile(login)
	ON DELETE SET NULL ON UPDATE NO ACTION
);

-- DebtStatus
CREATE TABLE debt_status (
    debt_status_id SERIAL PRIMARY KEY,
    debt_status_name VARCHAR(16) NOT NULL
);

-- Debt
CREATE TABLE debt (
    debt_id SERIAL PRIMARY KEY,
    payer_id VARCHAR(20) NOT NULL,
    recipient_id VARCHAR(20) NOT NULL,
    status_id INTEGER NOT NULL,
    debt_amount DECIMAL(10, 2) NOT NULL,
    event_id INTEGER NOT NULL,
    FOREIGN KEY (payer_id) REFERENCES user_profile(login)
	ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (recipient_id) REFERENCES user_profile(login)
	ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (status_id) REFERENCES debt_status(debt_status_id)
	ON DELETE NO ACTION ON UPDATE NO ACTION,
    FOREIGN KEY (event_id) REFERENCES event(event_id)
	ON DELETE NO ACTION ON UPDATE NO ACTION
);

CREATE VIEW purchase_with_payer_view AS
SELECT
    purchase.purchase_id AS purchase_id,
    purchase.purchase_name AS purchase_name,
    purchase.purchase_description AS purchase_description,
    (
        SELECT purchase.cost / (COUNT(*) + 1)
        FROM payer
        WHERE payer.purchase_id = purchase.purchase_id
        GROUP BY purchase.cost
        ) AS cost,
    purchase.responsible_user AS recipient,
    payer.user_id AS payer,
    purchase.event_id AS event_id
FROM purchase
         JOIN payer ON purchase.purchase_id = payer.purchase_id;

-- Заполнение справочных таблиц

-- EventStatus
INSERT INTO event_status (event_status_name) VALUES ('активно');
INSERT INTO event_status (event_status_name) VALUES ('завершено');
INSERT INTO event_status (event_status_name) VALUES ('удалено');

-- TaskStatus
INSERT INTO task_status (task_status_name) VALUES ('выполнена');
INSERT INTO task_status (task_status_name) VALUES ('не выполнена');

-- DebtStatus
INSERT INTO debt_status (debt_status_name) VALUES ('не оплачен');
INSERT INTO debt_status (debt_status_name) VALUES ('оплачен');
INSERT INTO debt_status (debt_status_name) VALUES ('получен');

-- Role
INSERT INTO role (role_name) VALUES ('участник');
INSERT INTO role (role_name) VALUES ('организатор');
INSERT INTO role (role_name) VALUES ('создатель');
INSERT INTO role (role_name) VALUES ('не допущен');

-- Создание индексов
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX idx_userprofile_name_surname ON user_profile(LOWER(name), LOWER(surname));
CREATE INDEX idx_event_user_list ON event_user_list(event_id, LOWER(user_id));

CREATE INDEX ON user_profile (LOWER(name));
CREATE INDEX ON user_profile (LOWER(surname));
CREATE INDEX ON user_secret  (LOWER(email));


CREATE INDEX user_profile_name_trgm_idx
  ON user_profile USING gin (LOWER(name) gin_trgm_ops);

CREATE INDEX user_profile_surname_trgm_idx
  ON user_profile USING gin (LOWER(surname) gin_trgm_ops);

CREATE INDEX user_secret_email_trgm_idx
  ON user_secret  USING gin (LOWER(email) gin_trgm_ops);

  

CREATE INDEX idx_purchase_responsible_user ON purchase(responsible_user);
CREATE INDEX idx_purchase_event_id ON purchase(event_id);

CREATE INDEX idx_stuff_event_id ON stuff(event_id);
CREATE INDEX idx_stuff_responsible_user ON stuff(responsible_user);


CREATE INDEX idx_task_responsible_user ON task(responsible_user);
CREATE INDEX idx_task_event_id ON task(event_id);

CREATE INDEX idx_debt_payer_id ON debt(payer_id);
CREATE INDEX idx_debt_recipient_id ON debt(recipient_id);
CREATE INDEX idx_debt_event_id ON debt(event_id);

CREATE INDEX idx_payer_user_id ON payer(user_id);

CREATE INDEX idx_receiptlist_purchase_id ON receipt_list(purchase_id);


ALTER TABLE payer 
ADD CONSTRAINT uk_payer UNIQUE (purchase_id, user_id);

ALTER TABLE receipt_list 
ADD CONSTRAINT uk_receipt_list UNIQUE (purchase_id, receipt_id);

ALTER TABLE event_user_list 
ADD CONSTRAINT uk_event_user_list UNIQUE (event_id, user_id);