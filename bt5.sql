DROP DATABASE IF EXISTS hospital_bed_management;
CREATE DATABASE hospital_bed_management;
USE hospital_bed_management;

CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL
);

CREATE TABLE beds (
    bed_id INT PRIMARY KEY,
    dept_id INT NOT NULL,
    status VARCHAR(20) NOT NULL,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE patients (
    patient_id INT PRIMARY KEY,
    bed_id INT,
    status VARCHAR(20) NOT NULL,
    FOREIGN KEY (bed_id) REFERENCES beds(bed_id)
);

INSERT INTO departments VALUES 
(1, 'Cardiology'), 
(2, 'Neurology'), 
(3, 'Pediatrics');

INSERT INTO beds VALUES 
(101, 1, 'Occupied'), 
(102, 1, 'Available'),
(201, 2, 'Occupied'), 
(202, 2, 'Occupied'),
(301, 3, 'Available');

INSERT INTO patients VALUES 
(1001, 101, 'Active'),
(1002, 201, 'Completed'),
(1003, 202, 'Active');

DELIMITER $$

CREATE PROCEDURE usp_find_available_bed(
    IN p_dept_id INT,
    OUT p_bed_id INT,
    OUT p_dept_name VARCHAR(100)
)
BEGIN
    SET p_bed_id = NULL;
    SET p_dept_name = NULL;

    SELECT dept_name INTO p_dept_name
    FROM departments
    WHERE dept_id = p_dept_id;

    SELECT bed_id INTO p_bed_id
    FROM beds
    WHERE dept_id = p_dept_id AND status = 'Available'
    LIMIT 1
    FOR UPDATE;
END$$

CREATE PROCEDURE usp_transfer_patient_bed(
    IN p_patient_id INT,
    IN p_target_dept_id INT,
    OUT p_result_bed_id INT,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_patient_status VARCHAR(20);
    DECLARE v_old_bed_id INT;
    DECLARE v_new_bed_id INT;
    DECLARE v_dept_name VARCHAR(100);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_message = 'Internal database error. Transaction rolled back.';
        SET p_result_bed_id = NULL;
    END;

    START TRANSACTION;

    SELECT status, bed_id INTO v_patient_status, v_old_bed_id
    FROM patients
    WHERE patient_id = p_patient_id
    FOR UPDATE;

    IF v_patient_status IS NULL THEN
        SET p_message = 'Error: Patient not found.';
        SET p_result_bed_id = NULL;
        ROLLBACK;
    ELSEIF v_patient_status = 'Completed' THEN
        SET p_message = 'Error: Patient already discharged.';
        SET p_result_bed_id = NULL;
        ROLLBACK;
    ELSE
        CALL usp_find_available_bed(p_target_dept_id, v_new_bed_id, v_dept_name);

        IF v_dept_name IS NULL THEN
            SET p_message = 'Error: Target department does not exist.';
            SET p_result_bed_id = NULL;
            ROLLBACK;
        ELSEIF v_new_bed_id IS NULL THEN
            SET p_message = CONCAT('Từ chối: Khoa ', v_dept_name, ' đã hết giường');
            SET p_result_bed_id = NULL;
            ROLLBACK;
        ELSE
            IF v_old_bed_id IS NOT NULL THEN
                UPDATE beds SET status = 'Available' WHERE bed_id = v_old_bed_id;
            END IF;

            UPDATE beds SET status = 'Occupied' WHERE bed_id = v_new_bed_id;
            UPDATE patients SET bed_id = v_new_bed_id WHERE patient_id = p_patient_id;

            SET p_result_bed_id = v_new_bed_id;
            SET p_message = 'Success: Bed transferred and locked safely.';
            COMMIT;
        END IF;
    END IF;
END$$

DELIMITER ;

SET @out_bed = NULL;
SET @out_msg = '';

CALL usp_transfer_patient_bed(1001, 3, @out_bed, @out_msg);
SELECT 'Test 1: Success Transfer' AS Test_Case, @out_bed AS Result_Bed_ID, @out_msg AS Status_Message;

CALL usp_transfer_patient_bed(1003, 2, @out_bed, @out_msg);
SELECT 'Test 2: Overbooking Trap' AS Test_Case, @out_bed AS Result_Bed_ID, @out_msg AS Status_Message;

CALL usp_transfer_patient_bed(1002, 1, @out_bed, @out_msg);
SELECT 'Test 3: Discharged Patient Trap' AS Test_Case, @out_bed AS Result_Bed_ID, @out_msg AS Status_Message;

CALL usp_transfer_patient_bed(1001, 99, @out_bed, @out_msg);
SELECT 'Test 4: Invalid Dept_ID' AS Test_Case, @out_bed AS Result_Bed_ID, @out_msg AS Status_Message;