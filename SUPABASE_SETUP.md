# DriveID App - Supabase Integration Setup

This Flutter app has been integrated with Supabase for backend data storage. Follow these steps to set up your Supabase project.

## 1. Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and create an account
2. Create a new project
3. Wait for the project to be set up

## 2. Get Your Project Credentials

1. In your Supabase dashboard, go to Settings > API
2. Copy your Project URL and anon/public key
3. Update `lib/config/supabase_config.dart` with your credentials:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://your-project-id.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key-here';
  // ... rest of the code
}
```

## 3. Set Up Database Tables

Run these SQL commands in your Supabase SQL Editor:

### Create officers table (for Traffic Officers, Licensing Officers, Admins):
```sql
CREATE TABLE officers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  auth_user_id UUID REFERENCES auth.users(id),
  email TEXT UNIQUE NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('traffic_officer', 'licensing_officer', 'admin')),
  employment_number TEXT UNIQUE,
  station TEXT,
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default admin user (replace with your email)
INSERT INTO officers (email, first_name, last_name, role, employment_number, station) 
VALUES ('admin@driveid.gov', 'System', 'Administrator', 'admin', 'ADMIN001', 'Central Office');
```

### Create drivers table:
```sql
CREATE TABLE drivers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  auth_user_id UUID REFERENCES auth.users(id),
  email TEXT UNIQUE,
  full_name TEXT NOT NULL,
  date_of_birth DATE,
  phone TEXT,
  address TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Create licenses table:
```sql
CREATE TABLE licenses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  driver_id UUID REFERENCES drivers(id) ON DELETE CASCADE,
  register_number TEXT UNIQUE NOT NULL,
  license_class TEXT NOT NULL,
  issue_date DATE NOT NULL,
  expiry_date DATE NOT NULL,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'suspended', 'revoked')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Create offense_types table:
```sql
CREATE TABLE offense_types (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  label TEXT NOT NULL,
  fine TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default offense types
INSERT INTO offense_types (label, fine) VALUES
  ('Speeding', 'MWK 25,000'),
  ('Driving without license', 'MWK 50,000'),
  ('Reckless driving', 'MWK 75,000'),
  ('Drunk driving', 'MWK 100,000'),
  ('Dangerous driving', 'MWK 150,000');
```

### Create offenses table:
```sql
CREATE TABLE offenses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  registration_number TEXT NOT NULL,
  offense_type_id UUID REFERENCES offense_types(id),
  offense_type TEXT NOT NULL,
  location TEXT NOT NULL,
  status TEXT DEFAULT 'Pending',
  fine TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Create verifications table:
```sql
CREATE TABLE verifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  registration_number TEXT NOT NULL,
  verified_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 4. Enable Row Level Security (Optional but Recommended)

For production apps, enable RLS and create policies:

```sql
-- Enable RLS
ALTER TABLE offenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE offense_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE officers ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE licenses ENABLE ROW LEVEL SECURITY;

-- Create policies (adjust based on your auth requirements)
CREATE POLICY "Allow all operations on offenses" ON offenses FOR ALL USING (true);
CREATE POLICY "Allow all operations on verifications" ON verifications FOR ALL USING (true);
CREATE POLICY "Allow read access to offense_types" ON offense_types FOR SELECT USING (true);
CREATE POLICY "Allow officers to read their own data" ON officers FOR SELECT USING (auth.uid() = auth_user_id);
CREATE POLICY "Allow drivers to read their own data" ON drivers FOR SELECT USING (auth.uid() = auth_user_id);
CREATE POLICY "Allow drivers to read their licenses" ON licenses FOR SELECT USING (
  driver_id IN (SELECT id FROM drivers WHERE auth_user_id = auth.uid())
);
```

## 5. Account Creation Process

### User Roles & Permissions:
- **Admin**: Can create/manage all officer accounts, full system access
- **Licensing Officer**: Can create driver accounts and licenses, manage licensing
- **Traffic Officer**: Can verify licenses, record offenses (mobile app)
- **Driver**: Can view their license info (mobile app)

### Creating Accounts:

#### For Admins (Manual Setup):
1. Create admin user in Supabase Auth dashboard
2. Insert admin record in `officers` table with `role = 'admin'`

#### For Officers:
- **Only admins can create officer accounts** through database inserts or admin interface
- Officers use email/password authentication

#### For Drivers:
- **Licensing officers create driver accounts** through desktop application
- Drivers authenticate via eSignet (external service)
- System links eSignet users to existing driver records

### Authentication Flow:
1. **Email/Password** (Officers): Direct Supabase auth + role lookup
2. **eSignet** (Drivers): External auth → link to existing driver record

## 6. Install Dependencies

Run:
```bash
flutter pub get
```

## 7. Run the App

```bash
flutter run
```

## Features Added

- **User Authentication**: Role-based access (Admin, Licensing Officer, Traffic Officer, Driver)
- **Dashboard Stats**: Real-time statistics from Supabase
- **Offense Management**: Create and view offenses stored in Supabase
- **License Verification**: Record verification events in Supabase
- **Dynamic Offense Types**: Configurable offense types from database

## API Reference

The app uses these Supabase tables:
- `officers`: Stores officer profiles (traffic officers, licensing officers, admins)
- `drivers`: Stores driver profiles
- `licenses`: Stores driving license information
- `offenses`: Stores traffic violation records
- `offense_types`: Stores available offense types and fines
- `verifications`: Stores license verification records

All data operations are handled through the service classes in `lib/services/`.