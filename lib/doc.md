# Multi-Location Time Clock System - Database Schema

## Overview

This schema supports:
- Multiple work locations per company
- Employees assigned to one or more locations
- Different geofence settings per location
- Location-based shift scheduling
- Flexible assignment rules

---

## Database Tables

### 1. Locations Table

Stores all work locations with their geofence settings.

```sql
CREATE TABLE locations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  
  -- Basic Info
  name TEXT NOT NULL,                    -- e.g., "Main Office, Berlin"
  address TEXT,                          -- "Friedrichstraße 123, 10117 Berlin"
  location_code TEXT UNIQUE,             -- Short code: "BERLIN_MAIN", "NYC_WAREHOUSE"
  
  -- Geofence Settings
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  geofence_radius_meters REAL NOT NULL DEFAULT 200.0,
  gps_buffer_meters REAL NOT NULL DEFAULT 10.0,
  
  -- Location Type
  location_type TEXT DEFAULT 'office',   -- office, warehouse, construction_site, retail, remote
  
  -- Status
  is_active BOOLEAN DEFAULT 1,
  requires_geofence BOOLEAN DEFAULT 1,   -- Some locations might not require geofence
  
  -- Metadata
  timezone TEXT DEFAULT 'UTC',           -- e.g., 'Europe/Berlin'
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  -- Manager/Contact
  manager_name TEXT,
  manager_email TEXT,
  contact_phone TEXT
);

-- Indexes
CREATE INDEX idx_locations_active ON locations(is_active);
CREATE INDEX idx_locations_code ON locations(location_code);
```

---

### 2. Employee Location Assignments Table

Links employees to locations they can clock in at.

```sql
CREATE TABLE employee_locations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  
  employee_id INTEGER NOT NULL,
  location_id INTEGER NOT NULL,
  
  -- Assignment Details
  is_primary_location BOOLEAN DEFAULT 0,     -- One primary location per employee
  can_clock_in BOOLEAN DEFAULT 1,
  
  -- Schedule (Optional)
  valid_from DATE,                           -- Assignment start date
  valid_to DATE,                             -- Assignment end date (NULL = indefinite)
  
  -- Specific days this employee works at this location
  works_monday BOOLEAN DEFAULT 1,
  works_tuesday BOOLEAN DEFAULT 1,
  works_wednesday BOOLEAN DEFAULT 1,
  works_thursday BOOLEAN DEFAULT 1,
  works_friday BOOLEAN DEFAULT 1,
  works_saturday BOOLEAN DEFAULT 0,
  works_sunday BOOLEAN DEFAULT 0,
  
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE CASCADE,
  FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE,
  
  -- Ensure employee only has one primary location
  UNIQUE(employee_id, location_id)
);

-- Indexes
CREATE INDEX idx_employee_locations_employee ON employee_locations(employee_id);
CREATE INDEX idx_employee_locations_location ON employee_locations(location_id);
CREATE INDEX idx_employee_locations_primary ON employee_locations(employee_id, is_primary_location);
```

---

### 3. Updated Clock-Ins Table

```sql
CREATE TABLE clock_ins (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  
  employee_id INTEGER NOT NULL,
  location_id INTEGER NOT NULL,              -- NEW: Which location they clocked in at
  
  -- Timestamp
  clock_in_time DATETIME NOT NULL,
  
  -- GPS Data
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  gps_accuracy REAL,
  distance_from_location REAL NOT NULL,      -- Distance from assigned location
  within_geofence BOOLEAN NOT NULL,
  
  -- Location Context (snapshot at time of clock-in)
  location_name TEXT,                        -- Snapshot of location name
  location_latitude REAL,                    -- Snapshot of location coords
  location_longitude REAL,
  geofence_radius REAL,
  
  -- Override/Manual Entry
  is_manual_entry BOOLEAN DEFAULT 0,
  manual_entry_reason TEXT,
  approved_by INTEGER,                       -- Manager who approved override
  
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (employee_id) REFERENCES employees(id),
  FOREIGN KEY (location_id) REFERENCES locations(id),
  FOREIGN KEY (approved_by) REFERENCES employees(id)
);

CREATE INDEX idx_clock_ins_employee ON clock_ins(employee_id);
CREATE INDEX idx_clock_ins_location ON clock_ins(location_id);
CREATE INDEX idx_clock_ins_time ON clock_ins(clock_in_time DESC);
```

---

### 4. Updated Clock-Outs Table

```sql
CREATE TABLE clock_outs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  
  employee_id INTEGER NOT NULL,
  clock_in_id INTEGER,                       -- Link to corresponding clock-in
  location_id INTEGER,                       -- May differ from clock-in location
  
  -- Timestamp
  clock_out_time DATETIME NOT NULL,
  
  -- GPS Data (nullable - clock-out allowed from anywhere)
  latitude REAL,
  longitude REAL,
  gps_accuracy REAL,
  distance_from_location REAL,
  within_geofence BOOLEAN,
  
  -- Location Status Tracking
  location_status TEXT NOT NULL,             -- success, timeout, permission_denied, etc.
  location_note TEXT NOT NULL,
  
  -- Session Info
  session_duration TEXT,                     -- Calculated from clock-in
  
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (employee_id) REFERENCES employees(id),
  FOREIGN KEY (clock_in_id) REFERENCES clock_ins(id),
  FOREIGN KEY (location_id) REFERENCES locations(id)
);

CREATE INDEX idx_clock_outs_employee ON clock_outs(employee_id);
CREATE INDEX idx_clock_outs_location ON clock_outs(location_id);
CREATE INDEX idx_clock_outs_time ON clock_outs(clock_out_time DESC);
CREATE INDEX idx_clock_outs_status ON clock_outs(location_status);
```

---

### 5. Employees Table (Updated)

```sql
CREATE TABLE employees (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  
  -- Basic Info
  employee_code TEXT UNIQUE NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  
  -- Employment
  job_title TEXT,
  department TEXT,
  employment_type TEXT,                      -- full_time, part_time, contractor
  hire_date DATE,
  
  -- Default Location
  default_location_id INTEGER,               -- Their usual location
  
  -- Account
  is_active BOOLEAN DEFAULT 1,
  is_manager BOOLEAN DEFAULT 0,
  
  -- App/Auth
  device_id TEXT,                            -- Mobile device identifier
  last_login DATETIME,
  
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  
  FOREIGN KEY (default_location_id) REFERENCES locations(id)
);

CREATE INDEX idx_employees_active ON employees(is_active);
CREATE INDEX idx_employees_code ON employees(employee_code);
CREATE INDEX idx_employees_email ON employees(email);
CREATE INDEX idx_employees_default_location ON employees(default_location_id);
```

---

## Sample Data

### Locations

```sql
INSERT INTO locations (name, address, latitude, longitude, geofence_radius_meters, gps_buffer_meters, location_code, location_type, timezone) VALUES
('Main Office, Berlin', 'Friedrichstraße 123, 10117 Berlin', 52.5200, 13.4050, 200, 10, 'BERLIN_MAIN', 'office', 'Europe/Berlin'),
('Warehouse Hamburg', 'Industriestraße 45, 20537 Hamburg', 53.5511, 9.9937, 300, 15, 'HAMBURG_WH', 'warehouse', 'Europe/Berlin'),
('Construction Site Munich', 'Baustraße 89, 80331 München', 48.1351, 11.5820, 500, 25, 'MUNICH_CONST', 'construction_site', 'Europe/Berlin'),
('NYC Office', '123 Broadway, New York, NY 10006', 40.7128, -74.0060, 200, 10, 'NYC_OFFICE', 'office', 'America/New_York'),
('Remote Work', 'N/A', 0, 0, 0, 0, 'REMOTE', 'remote', 'UTC');

UPDATE locations SET requires_geofence = 0 WHERE location_code = 'REMOTE';
```

### Employees

```sql
INSERT INTO employees (employee_code, first_name, last_name, email, job_title, department, default_location_id) VALUES
('EMP001', 'John', 'Doe', 'john.doe@company.com', 'Floor Manager', 'Operations', 1),
('EMP002', 'Jane', 'Smith', 'jane.smith@company.com', 'Warehouse Lead', 'Logistics', 2),
('EMP003', 'Bob', 'Johnson', 'bob.johnson@company.com', 'Site Supervisor', 'Construction', 3),
('EMP004', 'Alice', 'Wong', 'alice.wong@company.com', 'Software Engineer', 'Engineering', 4),
('EMP005', 'Chris', 'Lee', 'chris.lee@company.com', 'Remote Consultant', 'Consulting', 5);
```

### Employee Location Assignments

```sql
-- John works at Berlin office (primary) and sometimes at Hamburg warehouse
INSERT INTO employee_locations (employee_id, location_id, is_primary_location) VALUES
(1, 1, 1),  -- Berlin is primary
(1, 2, 0);  -- Can also work at Hamburg

-- Jane only works at Hamburg warehouse
INSERT INTO employee_locations (employee_id, location_id, is_primary_location) VALUES
(2, 2, 1);

-- Bob works at Munich construction site (Mon-Fri only)
INSERT INTO employee_locations (employee_id, location_id, is_primary_location, works_saturday, works_sunday) VALUES
(3, 3, 1, 0, 0);

-- Alice splits time between NYC and remote
INSERT INTO employee_locations (employee_id, location_id, is_primary_location, works_monday, works_tuesday, works_wednesday, works_thursday, works_friday) VALUES
(4, 4, 1, 1, 1, 0, 0, 0),  -- NYC Mon-Tue
(4, 5, 0, 0, 0, 1, 1, 1);  -- Remote Wed-Fri

-- Chris is fully remote
INSERT INTO employee_locations (employee_id, location_id, is_primary_location) VALUES
(5, 5, 1);
```

---

## Useful Queries

### Get All Locations an Employee Can Clock In At

```sql
SELECT 
  l.id,
  l.name,
  l.address,
  l.latitude,
  l.longitude,
  l.geofence_radius_meters,
  l.gps_buffer_meters,
  l.location_type,
  el.is_primary_location,
  l.requires_geofence
FROM locations l
JOIN employee_locations el ON l.id = el.location_id
WHERE el.employee_id = ?
  AND l.is_active = 1
  AND el.can_clock_in = 1
  AND (el.valid_to IS NULL OR el.valid_to >= DATE('now'))
ORDER BY el.is_primary_location DESC, l.name;
```

---

### Get Employee's Primary Location

```sql
SELECT 
  l.*
FROM locations l
JOIN employee_locations el ON l.id = el.location_id
WHERE el.employee_id = ?
  AND el.is_primary_location = 1
  AND l.is_active = 1
LIMIT 1;
```

---

### Check if Employee Can Clock In at Location Today

```sql
SELECT 
  CASE 
    WHEN COUNT(*) > 0 THEN 1 
    ELSE 0 
  END as can_clock_in
FROM employee_locations el
JOIN locations l ON el.location_id = l.id
WHERE el.employee_id = ?
  AND el.location_id = ?
  AND l.is_active = 1
  AND el.can_clock_in = 1
  AND (el.valid_to IS NULL OR el.valid_to >= DATE('now'))
  AND (
    (CAST(strftime('%w', 'now') AS INTEGER) = 0 AND el.works_sunday = 1) OR
    (CAST(strftime('%w', 'now') AS INTEGER) = 1 AND el.works_monday = 1) OR
    (CAST(strftime('%w', 'now') AS INTEGER) = 2 AND el.works_tuesday = 1) OR
    (CAST(strftime('%w', 'now') AS INTEGER) = 3 AND el.works_wednesday = 1) OR
    (CAST(strftime('%w', 'now') AS INTEGER) = 4 AND el.works_thursday = 1) OR
    (CAST(strftime('%w', 'now') AS INTEGER) = 5 AND el.works_friday = 1) OR
    (CAST(strftime('%w', 'now') AS INTEGER) = 6 AND el.works_saturday = 1)
  );
```

---

### Clock-Ins by Location (Manager View)

```sql
SELECT 
  l.name as location_name,
  COUNT(*) as total_clock_ins,
  COUNT(CASE WHEN ci.within_geofence = 1 THEN 1 END) as within_geofence,
  COUNT(CASE WHEN ci.within_geofence = 0 THEN 1 END) as outside_geofence,
  AVG(ci.distance_from_location) as avg_distance
FROM clock_ins ci
JOIN locations l ON ci.location_id = l.id
WHERE ci.clock_in_time >= DATE('now', '-30 days')
GROUP BY l.id, l.name
ORDER BY total_clock_ins DESC;
```

---

### Employees Currently On Duty at Each Location

```sql
SELECT 
  l.name as location_name,
  e.first_name || ' ' || e.last_name as employee_name,
  ci.clock_in_time,
  ROUND((JULIANDAY('now') - JULIANDAY(ci.clock_in_time)) * 24, 2) as hours_on_duty
FROM clock_ins ci
JOIN locations l ON ci.location_id = l.id
JOIN employees e ON ci.employee_id = e.id
LEFT JOIN clock_outs co ON co.clock_in_id = ci.id
WHERE co.id IS NULL  -- No corresponding clock-out
ORDER BY l.name, ci.clock_in_time;
```

---

## Migration Strategy

### If You Have Existing Data

```sql
-- Step 1: Create new tables
-- (use schema above)

-- Step 2: Create default location for existing data
INSERT INTO locations (name, address, latitude, longitude, location_code, location_type)
VALUES ('Legacy Location', 'Unknown', 52.5200, 13.4050, 'LEGACY', 'office');

-- Step 3: Assign all existing employees to legacy location
INSERT INTO employee_locations (employee_id, location_id, is_primary_location)
SELECT id, (SELECT id FROM locations WHERE location_code = 'LEGACY'), 1
FROM employees;

-- Step 4: Update existing clock-ins to reference legacy location
ALTER TABLE clock_ins ADD COLUMN location_id INTEGER;
UPDATE clock_ins SET location_id = (SELECT id FROM locations WHERE location_code = 'LEGACY');

-- Step 5: Update existing clock-outs to reference legacy location
ALTER TABLE clock_outs ADD COLUMN location_id INTEGER;
UPDATE clock_outs SET location_id = (SELECT id FROM locations WHERE location_code = 'LEGACY');

-- Step 6: Add real locations and reassign employees
-- (manual process based on your organization)
```

---

## Best Practices

1. **Primary Location**: Every employee should have exactly one primary location
2. **Location Codes**: Use consistent naming (e.g., CITY_TYPE format)
3. **Geofence Sizes**: Adjust based on location type:
   - Offices: 200m
   - Warehouses: 300m
   - Construction sites: 500m
   - Retail: 150m
4. **Remote Work**: Create a special "REMOTE" location with `requires_geofence = 0`
5. **Timezone**: Always store with location timezone for accurate shift calculations
6. **Valid Dates**: Use `valid_from` and `valid_to` for temporary assignments
7. **Audit Trail**: Keep location snapshots in clock-ins for historical accuracy
