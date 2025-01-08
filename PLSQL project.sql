-- Vehicles Table
CREATE TABLE vehicles (
    vehicle_id NUMBER PRIMARY KEY,
    vehicle_type VARCHAR2(50),
    capacity NUMBER,
    availability CHAR(1) DEFAULT 'Y' -- 'Y' for available, 'N' for unavailable
);

-- Drivers Table
CREATE TABLE drivers (
    driver_id NUMBER PRIMARY KEY,
    driver_name VARCHAR2(100),
    license_number VARCHAR2(50),
    availability CHAR(1) DEFAULT 'Y'
);

-- Routes Table
CREATE TABLE routes (
    route_id NUMBER PRIMARY KEY,
    source_location VARCHAR2(100),
    destination_location VARCHAR2(100),
    distance_km NUMBER
);

-- Trips Table
CREATE TABLE trips (
    trip_id NUMBER PRIMARY KEY,
    vehicle_id NUMBER REFERENCES vehicles(vehicle_id),
    driver_id NUMBER REFERENCES drivers(driver_id),
    route_id NUMBER REFERENCES routes(route_id),
    trip_date DATE,
    status VARCHAR2(50) DEFAULT 'Scheduled' -- Scheduled, Completed, Cancelled
);


CREATE OR REPLACE PROCEDURE add_vehicle(
    p_vehicle_id NUMBER,
    p_vehicle_type VARCHAR2,
    p_capacity NUMBER
) IS
BEGIN
    INSERT INTO vehicles(vehicle_id, vehicle_type, capacity)
    VALUES (p_vehicle_id, p_vehicle_type, p_capacity);
END;
/


CREATE OR REPLACE PROCEDURE add_driver(
    p_driver_id NUMBER,
    p_driver_name VARCHAR2,
    p_license_number VARCHAR2
) IS
BEGIN
    INSERT INTO drivers(driver_id, driver_name, license_number)
    VALUES (p_driver_id, p_driver_name, p_license_number);
END;
/


CREATE OR REPLACE PROCEDURE schedule_trip(
    p_trip_id NUMBER,
    p_vehicle_id NUMBER,
    p_driver_id NUMBER,
    p_route_id NUMBER,
    p_trip_date DATE
) IS
BEGIN
    INSERT INTO trips(trip_id, vehicle_id, driver_id, route_id, trip_date)
    VALUES (p_trip_id, p_vehicle_id, p_driver_id, p_route_id, p_trip_date);

    UPDATE vehicles
    SET availability = 'N'
    WHERE vehicle_id = p_vehicle_id;

    UPDATE drivers
    SET availability = 'N'
    WHERE driver_id = p_driver_id;
END;
/


CREATE OR REPLACE TRIGGER update_availability_after_trip
AFTER UPDATE OF status ON trips
FOR EACH ROW
BEGIN
    IF :NEW.status = 'Completed' THEN
        UPDATE vehicles
        SET availability = 'Y'
        WHERE vehicle_id = :NEW.vehicle_id;

        UPDATE drivers
        SET availability = 'Y'
        WHERE driver_id = :NEW.driver_id;
    END IF;
END;
/


CREATE OR REPLACE VIEW completed_trips AS
SELECT t.trip_id, v.vehicle_type, d.driver_name, r.source_location, r.destination_location, t.trip_date
FROM trips t
JOIN vehicles v ON t.vehicle_id = v.vehicle_id
JOIN drivers d ON t.driver_id = d.driver_id
JOIN routes r ON t.route_id = r.route_id
WHERE t.status = 'Completed';


-- Insert Vehicles
BEGIN
    add_vehicle(1, 'Truck', 10);
    add_vehicle(2, 'Van', 5);
END;
/

-- Insert Drivers
BEGIN
    add_driver(1, 'John Doe', 'LIC123');
    add_driver(2, 'Jane Smith', 'LIC456');
END;
/

-- Insert Routes
INSERT INTO routes(route_id, source_location, destination_location, distance_km)
VALUES (1, 'City A', 'City B', 150);

INSERT INTO routes(route_id, source_location, destination_location, distance_km)
VALUES (2, 'City B', 'City C', 200);

-- Schedule a Trip
BEGIN
    schedule_trip(1, 1, 1, 1, SYSDATE);
END;
/



CREATE OR REPLACE FUNCTION is_vehicle_available(p_vehicle_id NUMBER) RETURN CHAR IS
   v_availability CHAR(1);
BEGIN
   SELECT availability INTO v_availability
   FROM vehicles
   WHERE vehicle_id = p_vehicle_id;

   RETURN v_availability;
END;
/




CREATE OR REPLACE FUNCTION is_driver_available(p_driver_id NUMBER) RETURN CHAR IS
   v_availability CHAR(1);
BEGIN
   SELECT availability INTO v_availability
   FROM drivers
   WHERE driver_id = p_driver_id;

   RETURN v_availability;
END;
/


CREATE OR REPLACE FUNCTION calculate_trip_cost(p_route_id NUMBER, p_fuel_cost_per_km NUMBER) RETURN NUMBER IS
   v_distance NUMBER;
   v_trip_cost NUMBER;
BEGIN
   -- Fetch route distance
   SELECT distance_km INTO v_distance
   FROM routes
   WHERE route_id = p_route_id;

   -- Calculate cost
   v_trip_cost := v_distance * p_fuel_cost_per_km;
   RETURN v_trip_cost;
END;
/


CREATE OR REPLACE FUNCTION count_trips_by_driver(p_driver_id NUMBER) RETURN NUMBER IS
   v_trip_count NUMBER;
BEGIN
   SELECT COUNT(*)
   INTO v_trip_count
   FROM trips
   WHERE driver_id = p_driver_id;

   RETURN v_trip_count;
END;
/


CREATE OR REPLACE PROCEDURE add_route(
   p_route_id NUMBER,
   p_source_location VARCHAR2,
   p_destination_location VARCHAR2,
   p_distance_km NUMBER
) IS
BEGIN
   INSERT INTO routes(route_id, source_location, destination_location, distance_km)
   VALUES (p_route_id, p_source_location, p_destination_location, p_distance_km);
END;
/



CREATE OR REPLACE PROCEDURE complete_trip(p_trip_id NUMBER) IS
BEGIN
   UPDATE trips
   SET status = 'Completed'
   WHERE trip_id = p_trip_id;

   DBMS_OUTPUT.PUT_LINE('Trip with ID ' || p_trip_id || ' marked as completed.');
END;
/


CREATE OR REPLACE PROCEDURE cancel_trip(p_trip_id NUMBER) IS
BEGIN
   UPDATE trips
   SET status = 'Cancelled'
   WHERE trip_id = p_trip_id;

   -- Reset vehicle and driver availability
   UPDATE vehicles
   SET availability = 'Y'
   WHERE vehicle_id = (SELECT vehicle_id FROM trips WHERE trip_id = p_trip_id);

   UPDATE drivers
   SET availability = 'Y'
   WHERE driver_id = (SELECT driver_id FROM trips WHERE trip_id = p_trip_id);

   DBMS_OUTPUT.PUT_LINE('Trip with ID ' || p_trip_id || ' has been cancelled.');
END;
/

CREATE OR REPLACE PROCEDURE generate_driver_trip_report(p_driver_id NUMBER) IS
   CURSOR trip_cursor IS
      SELECT t.trip_id, t.trip_date, r.source_location, r.destination_location, t.status
      FROM trips t
      JOIN routes r ON t.route_id = r.route_id
      WHERE t.driver_id = p_driver_id;
   
   v_trip trip_cursor%ROWTYPE;
BEGIN
   DBMS_OUTPUT.PUT_LINE('Trip Report for Driver ID: ' || p_driver_id);
   DBMS_OUTPUT.PUT_LINE('---------------------------------------------');

   OPEN trip_cursor;
   LOOP
      FETCH trip_cursor INTO v_trip;
      EXIT WHEN trip_cursor%NOTFOUND;

      DBMS_OUTPUT.PUT_LINE('Trip ID: ' || v_trip.trip_id ||
                           ', Date: ' || v_trip.trip_date ||
                           ', Route: ' || v_trip.source_location || ' to ' || v_trip.destination_location ||
                           ', Status: ' || v_trip.status);
   END LOOP;

   CLOSE trip_cursor;
END;
/




CREATE OR REPLACE TRIGGER ensure_unique_assignment
BEFORE INSERT OR UPDATE ON trips
FOR EACH ROW
BEGIN
   -- Ensure vehicle is available
   IF is_vehicle_available(:NEW.vehicle_id) = 'N' THEN
      RAISE_APPLICATION_ERROR(-20002, 'Vehicle is already assigned to another trip.');
   END IF;

   -- Ensure driver is available
   IF is_driver_available(:NEW.driver_id) = 'N' THEN
      RAISE_APPLICATION_ERROR(-20003, 'Driver is already assigned to another trip.');
   END IF;
END;
/


BEGIN
   add_route(1, 'City A', 'City B', 100);
   add_route(2, 'City B', 'City C', 200);
END;
/

BEGIN
   schedule_trip(2, 2, 2, 2, SYSDATE + 1);
END;
/


SELECT is_vehicle_available(1) FROM DUAL;


SELECT calculate_trip_cost(2, 5) AS trip_cost FROM DUAL;

BEGIN
   generate_driver_trip_report(1);
END;
/
