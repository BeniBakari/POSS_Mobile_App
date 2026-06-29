import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SqliteService {
  static Future<Database> initializeDB() async {
    String path = await getDatabasesPath();
    return openDatabase(
      join(path, 'database.db'),
      onCreate: (database, version) async {
        await database.execute('''
            CREATE TABLE profile(
              id TEXT NOT NULL PRIMARY KEY,
              firstname TEXT NOT NULL, 
              lastname TEXT NOT NULL, 
              email TEXT NOT NULL, 
              dob TEXT, phone TEXT, 
              gender TEXT, 
              address TEXT, 
              roleId TEXT,
              roleNames TEXT,
              permissions TEXT, 
              imagePath TEXT, 
              token TEXT NOT NULL);
          ''');

        await database.execute('''
          CREATE TABLE users(
            id TEXT PRIMARY KEY NOT NULL,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            email TEXT NOT NULL,
            role_id TEXT,
            phone TEXT,
            imagePath TEXT,
            gender TEXT,
            address TEXT,
            roleNames TEXT,
            permissions TEXT, 
            dob TEXT
          );
        ''');

        await database.execute('''
          CREATE TABLE shops(
            id TEXT PRIMARY KEY NOT NULL, 
            name TEXT NOT NULL, 
            owner_id TEXT NOT NULL,  
            address TEXT NOT NULL);
        ''');

        await database.execute('''
          CREATE TABLE products(
            id TEXT PRIMARY KEY NOT NULL,
            shop_id TEXT NOT NULL,
            name TEXT NOT NULL,
            description TEXT NOT NULL,
            unit TEXT NOT NULL,
            unit_value NOT NULL,
            barcode TEXT NOT NULL,
            price TEXT NOT NULL,
            quantity TEXT NOT NULL,
            added_by TEXT NOT NULL,
            is_active TEXT
          );
        ''');
        await database.execute('''
          CREATE TABLE employees(
            id TEXT PRIMARY KEY NOT NULL,
            shop_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            added_by TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES users(id),
            FOREIGN KEY (added_by) REFERENCES users(id)
          );
        ''');

        await database.execute('''
            CREATE TABLE purchases(
              id TEXT PRIMARY KEY NOT NULL,
              cost TEXT NOT NULL,
              quantity TEXT NOT NULL,
              description TEXT,
              product_id TEXT NOT NULL,
              added_by TEXT NOT NULL,
              shop_id TEXT NOT NULL,
              FOREIGN KEY (added_by) REFERENCES users(id),
              FOREIGN KEY (product_id) REFERENCES products(id),
              FOREIGN KEY (shop_id) REFERENCES shops(id)                              
            );
        ''');

        await database.execute('''
            CREATE TABLE registers(
              id TEXT PRIMARY KEY NOT NULL,
              opening_cash TEXT NOT NULL,
              closing_cash TEXT NOT NULL,
              opened_by TEXT,
              closed_by TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              shop_id TEXT NOT NULL,
              FOREIGN KEY (opened_by) REFERENCES users(id),
              FOREIGN KEY (closed_by) REFERENCES users(id),
              FOREIGN KEY (shop_id) REFERENCES shops(id)                              
            );
        ''');

        await database.execute('''
            CREATE TABLE expenses(
              id TEXT PRIMARY KEY NOT NULL,
              description TEXT NOT NULL,
              amount TEXT NOT NULL,
              added_by TEXT NOT NULL,
              shop_id TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              FOREIGN KEY (added_by) REFERENCES users(id),
              FOREIGN KEY (shop_id) REFERENCES shops(id)                              
            );
        ''');
        await database.execute('''
            CREATE TABLE systemUser(
              id TEXT PRIMARY KEY NOT NULL,
              admins bool NOT NULL,
              technicians bool NOT NULL,
              shop_owners bool NOT NULL,
              managers bool NOT NULL,
              workers bool NOT NULL,
              unverified bool NOT NULL,
              unidentified bool NOT NULL,
              total bool NOT NULL                       
            );
        ''');
        await database.execute('''
          INSERT INTO systemUser(id,admins,technicians,shop_owners,managers,workers,unverified,unidentified,total) VALUES(
              "1",
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false
            );  
        ''');
      },
      version: 1,
    );
  }
}
