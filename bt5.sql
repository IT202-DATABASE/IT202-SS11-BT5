CREATE DATABASE IF NOT EXISTS RikkeiClinicDB;
USE RikkeiClinicDB;

CREATE TABLE IF NOT EXISTS Patients (
    patient_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    date_of_birth DATE
);

CREATE TABLE IF NOT EXISTS Employees (
    employee_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    position VARCHAR(50) NOT NULL,
    salary DECIMAL(18,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS Departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS Beds (
    bed_id INT PRIMARY KEY,
    dept_id INT NOT NULL,
    patient_id INT DEFAULT NULL,
    FOREIGN KEY (dept_id) REFERENCES Departments(dept_id),
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
);

CREATE TABLE IF NOT EXISTS Appointments (
    appointment_id INT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATETIME NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'Pending',
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (doctor_id) REFERENCES Employees(employee_id)
);

CREATE TABLE IF NOT EXISTS Inventory (
    item_id INT PRIMARY KEY,
    item_name VARCHAR(100) NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS Medicines (
    medicine_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(18,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS Patient_Invoices (
    patient_id INT PRIMARY KEY,
    total_due DECIMAL(18,2) NOT NULL DEFAULT 0,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
);

CREATE TABLE IF NOT EXISTS Products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    price DECIMAL(18,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS Services (
    service_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(18,2) NOT NULL
);

CREATE TABLE IF NOT EXISTS Wallets (
    patient_id INT PRIMARY KEY,
    balance DECIMAL(18,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'Active',
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
);

CREATE TABLE IF NOT EXISTS Service_Usages (
    usage_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    service_id INT NOT NULL,
    actual_price DECIMAL(18,2) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id),
    FOREIGN KEY (service_id) REFERENCES Services(service_id)
);

INSERT IGNORE INTO Patients (patient_id, full_name, phone, date_of_birth) VALUES
(1, 'Nguyen Van An', '0901111222', '1990-05-15'),
(2, 'Tran Thi Binh', '0912222333', '1985-08-20'),
(3, 'Le Hoang Cuong', '0923333444', '2000-12-01');

INSERT IGNORE INTO Employees (employee_id, full_name, position, salary) VALUES
(101, 'Dr. Hoang Minh', 'Doctor', 20000.00),
(102, 'Dr. Lan Anh', 'Doctor', 25000.00),
(103, 'Nurse Thu Ha', 'Nurse', 12000.00);

INSERT IGNORE INTO Departments (dept_id, dept_name) VALUES
(1, 'Khoa Ngoai'),
(2, 'Khoa Noi'),
(3, 'Khoa ICU');

INSERT IGNORE INTO Beds (bed_id, dept_id, patient_id) VALUES
(101, 1, 1),
(201, 2, NULL),
(301, 3, 2);

INSERT IGNORE INTO Appointments (appointment_id, patient_id, doctor_id, appointment_date, status) VALUES
(104, 1, 101, '2026-06-10 08:30:00', 'Pending'),
(105, 2, 102, '2026-05-01 09:00:00', 'Completed'),
(106, 3, 101, '2026-05-02 10:00:00', 'Cancelled');

INSERT IGNORE INTO Inventory (item_id, item_name, stock_quantity) VALUES
(10, 'Khau trang y te N95', 1000),
(11, 'Gang tay vo trung', 500),
(12, 'Dung dich sat khuan', 200);

INSERT IGNORE INTO Medicines (medicine_id, name, price, stock) VALUES
(1, 'Amoxicillin 500mg', 15000, 100),
(2, 'Panadol Extra', 5000, 5);

INSERT IGNORE INTO Patient_Invoices (patient_id, total_due) VALUES
(1, 1500000.00),
(2, 0),
(3, 0);

INSERT IGNORE INTO Products (name, price, stock) VALUES
('May do huyet ap Omron', 850000.00, 20),
('May do duong huyet', 450000.00, 15);

INSERT IGNORE INTO Services (service_id, name, price) VALUES
(1, 'Sieu am o bung', 200000.00),
(2, 'Xet nghiem mau', 150000.00),
(3, 'Chup X-Quang', 250000.00);

INSERT IGNORE INTO Wallets (patient_id, balance, status) VALUES
(1, 500000.00, 'Active'),
(2, 50000.00, 'Active'),
(3, 1000000.00, 'Inactive');

DROP PROCEDURE IF EXISTS CancelAppointment;
DELIMITER //
CREATE PROCEDURE CancelAppointment(IN p_appointment_id INT)
BEGIN
    UPDATE Appointments
    SET status = 'Cancelled'
    WHERE appointment_id = p_appointment_id 
      AND status = 'Pending';
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS AddInventory;
DELIMITER //
CREATE PROCEDURE AddInventory(IN p_item_id INT, IN p_quantity INT)
BEGIN
    IF p_quantity > 0 THEN
        UPDATE Inventory
        SET stock_quantity = stock_quantity + p_quantity
        WHERE item_id = p_item_id;
    END IF;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS CalculateDischargeCost;
DELIMITER //
CREATE PROCEDURE CalculateDischargeCost(
    IN p_total_cost DECIMAL(18,2),
    IN p_patient_type VARCHAR(20),
    OUT p_final_amount DECIMAL(18,2),
    OUT p_message VARCHAR(100)
)
BEGIN
    IF p_total_cost < 0 THEN
        SET p_final_amount = 0;
        SET p_message = 'Lỗi: Chi phí không hợp lệ';
    ELSE
        IF p_patient_type = 'BHYT' THEN
            SET p_final_amount = p_total_cost * 0.20;
        ELSEIF p_patient_type = 'VIP' THEN
            SET p_final_amount = p_total_cost * 0.90;
        ELSE
            SET p_final_amount = p_total_cost;
        END IF;
        
        SET p_message = 'Đã tính toán xong';
    END IF;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS GetPatientDebt;
DELIMITER //
CREATE PROCEDURE GetPatientDebt(
    IN p_patient_id INT,
    IN p_phone VARCHAR(15),
    OUT p_total_due DECIMAL(18,2),
    OUT p_message VARCHAR(100)
)
BEGIN
    DECLARE v_found_id INT DEFAULT NULL;
    DECLARE v_debt DECIMAL(18,2) DEFAULT NULL;

    IF p_patient_id IS NULL AND p_phone IS NULL THEN
        SET p_total_due = 0;
        SET p_message = 'Lỗi: Vui lòng nhập Mã bệnh nhân hoặc Số điện thoại!';
    ELSE
        IF p_patient_id IS NOT NULL THEN
            SELECT patient_id INTO v_found_id 
            FROM Patients 
            WHERE patient_id = p_patient_id LIMIT 1;
        ELSEIF p_phone IS NOT NULL THEN
            SELECT patient_id INTO v_found_id 
            FROM Patients 
            WHERE phone = p_phone LIMIT 1;
        END IF;

        IF v_found_id IS NULL THEN
            SET p_total_due = 0;
            SET p_message = 'Không tìm thấy thông tin bệnh nhân trong hệ thống.';
        ELSE
            SELECT total_due INTO v_debt 
            FROM Patient_Invoices 
            WHERE patient_id = v_found_id LIMIT 1;
            
            IF v_debt IS NULL THEN
                SET p_total_due = 0;
            ELSE
                SET p_total_due = v_debt;
            END IF;
            
            SET p_message = 'Tra cứu thành công.';
        END IF;
    END IF;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS FindEmptyBed;
DELIMITER //
CREATE PROCEDURE FindEmptyBed(
    IN p_dept_id INT,
    OUT p_empty_bed_id INT
)
BEGIN
    SET p_empty_bed_id = NULL;
    
    SELECT bed_id INTO p_empty_bed_id
    FROM Beds
    WHERE dept_id = p_dept_id AND patient_id IS NULL
    ORDER BY bed_id ASC
    LIMIT 1
    FOR UPDATE;
END //
DELIMITER ;

DROP PROCEDURE IF EXISTS TransferPatientBed;
DELIMITER //
CREATE PROCEDURE TransferPatientBed(
    IN p_patient_id INT,
    IN p_target_dept_id INT,
    OUT p_new_bed_id INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_target_dept_name VARCHAR(100) DEFAULT NULL;
    DECLARE v_appt_status VARCHAR(20) DEFAULT NULL;
    DECLARE v_current_bed_id INT DEFAULT NULL;
    DECLARE v_empty_bed_id INT DEFAULT NULL;

    SELECT dept_name INTO v_target_dept_name
    FROM Departments
    WHERE dept_id = p_target_dept_id;

    IF v_target_dept_name IS NULL THEN
        SET p_new_bed_id = NULL;
        SET p_message = 'Lỗi: Mã khoa chuyển đến không tồn tại!';
    ELSE
        SELECT status INTO v_appt_status
        FROM Appointments
        WHERE patient_id = p_patient_id
        ORDER BY appointment_date DESC
        LIMIT 1;

        IF v_appt_status = 'Completed' THEN
            SET p_new_bed_id = NULL;
            SET p_message = 'Lỗi: Hủy giao dịch. Bệnh nhân đã làm thủ tục xuất viện!';
        ELSE
            SELECT bed_id INTO v_current_bed_id
            FROM Beds
            WHERE patient_id = p_patient_id
            LIMIT 1;

            IF v_current_bed_id IS NULL THEN
                SET p_new_bed_id = NULL;
                SET p_message = 'Lỗi: Bệnh nhân hiện không nằm trên giường nào!';
            ELSE
                START TRANSACTION;

                CALL FindEmptyBed(p_target_dept_id, v_empty_bed_id);

                IF v_empty_bed_id IS NULL THEN
                    ROLLBACK;
                    SET p_new_bed_id = NULL;
                    SET p_message = CONCAT('Từ chối: Khoa ', v_target_dept_name, ' đã hết giường');
                ELSE
                    UPDATE Beds SET patient_id = NULL WHERE bed_id = v_current_bed_id;
                    UPDATE Beds SET patient_id = p_patient_id WHERE bed_id = v_empty_bed_id;
                    
                    COMMIT;
                    
                    SET p_new_bed_id = v_empty_bed_id;
                    SET p_message = CONCAT('Thành công: Đã chuyển sang giường ', v_empty_bed_id, ' (', v_target_dept_name, ')');
                END IF;
            END IF;
        END IF;
    END IF;
END //
DELIMITER ;