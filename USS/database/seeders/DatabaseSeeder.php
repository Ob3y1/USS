<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * @return void
     */
    public function run()
    {
    
        DB::table('roles')->insert([
            ['role' => 'Admin'],
            ['role' => 'Supervisor'], 
        ]);
        DB::table('users')->insert([
            [
                'name' => 'Admin User',
                'email' => 'admin@example.com',
                'password' => Hash::make('111q'),
                'role_id' => 1, // Admin
            ],
            [
                'name' => 'Support Agent',
                'email' => 'support@example.com',
                'password' => Hash::make('111w'),
                'role_id' => 2,
            ],
        ]);
      

    }
}
