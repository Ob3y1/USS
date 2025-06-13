<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

use App\Models\User;
use App\Models\Subject;
use App\Models\ExamDay;
use App\Models\ExamTime;
use App\Models\WorkingDay;
use App\Models\Specialty;
use App\Models\Hall;
use App\Models\Camera;
use App\Models\WorkingDaysForUser;

class AdminController extends Controller
{

    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required'
        ]);
    
        $user = User::where('email', $request->email)->with('role')->first();
    
        // التحقق من صحة البريد وكلمة المرور
        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }
    
        // التحقق من الدور: فقط admin يُسمح له بتسجيل الدخول هنا
        if ($user->role->role !== 'Admin') {
            return response()->json(['message' => 'Access denied. Only admin can log in here.'], 403);
        }
    
        $token = $user->createToken('auth-token')->plainTextToken;
    
        return response()->json([
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role->role
            ]
        ],201);
    }
    
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Logged out'],201);
    }

    public function showprofile(Request $request)
    {
        return response()->json([
            'message' => 'User profile fetched successfully',
            'user' => $request->user(),
        ], 201); // OK
    }
    public function updateprofile(Request $request)
    { 
        try {
            $user = $request->user();
            
            if (!$user) {
                return response()->json(['message' => 'Unauthenticated.'], 401);
            }
            $request->validate([
                'name' => 'sometimes|string|max:255',
                'email' => 'sometimes|email|unique:users,email,' . $user->id,
                'password' => 'sometimes|string|min:4',
            ]);

            if ($request->has('name')) {
                $user->name = $request->name;
            }

            if ($request->has('email')) {
                $user->email = $request->email;
            }

            if ($request->has('password')) {
                $user->password = Hash::make($request->password);
            }

            $user->save();

            return response()->json([
                'message' => 'Profile updated successfully.',
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'role' => $user->role->role,
                ]
            ],201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validation Error',
                'errors' => $e->errors(), // Returns an array of errors for each field
            ], 422); // 422 Unprocessable Entity
        }
    }
   


    public function addExamDay(Request $request)
    {
        try{
            $validated = $request->validate([
                'day' => 'required|string|max:255',
                'date' => 'required|date',
            ]);
        
            $examDay = ExamDay::create($validated);
        
            return response()->json([
                'message' => 'Exam day added successfully.',
                'day' => $examDay
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validation Error',
                'errors' => $e->errors(), // Returns an array of errors for each field
            ], 422); // 422 Unprocessable Entity
        }
    }
        
    public function addExamTime(Request $request)
    {
        try{
            $validated = $request->validate([
                'time' => 'required|string|max:255', // مثال: '09:00 AM - 11:00 AM'
            ]);

            $examTime = ExamTime::create($validated);

            return response()->json([
                'message' => 'Exam time added successfully.',
                'time' => $examTime
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validation Error',
                'errors' => $e->errors(), // Returns an array of errors for each field
            ], 422); // 422 Unprocessable Entity
        }  
    }
    public function updateExamDay(Request $request, $id)
    {
        try {
            $validated = $request->validate([
                'day' => 'required|string|max:255',
                'date' => 'required|date',
            ]);
    
            $examDay = ExamDay::findOrFail($id);
            $examDay->update($validated);
    
            return response()->json([
                'message' => 'تم تعديل يوم الامتحان بنجاح.',
                'day' => $examDay
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'خطأ في التحقق من البيانات.',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'حدث خطأ أثناء التعديل.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
    public function updateExamTime(Request $request, $id)
    {
        try {
            $validated = $request->validate([
                'time' => 'required|string|max:255', // مثال: '09:00 AM - 11:00 AM'
            ]);
    
            $examTime = ExamTime::findOrFail($id);
            $examTime->update($validated);
    
            return response()->json([
                'message' => 'تم تعديل توقيت الامتحان بنجاح.',
                'time' => $examTime
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'خطأ في التحقق من البيانات.',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'حدث خطأ أثناء التعديل.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
        
    public function addWorkingDay(Request $request)
    {
        try{
            $request->validate([
                'day' => 'required|string|in:Saturday,Sunday,Monday,Tuesday,Wednesday,Thursday,Friday',
            ]);
        
            $workingDay = WorkingDay::create([
                'day' => $request->day,
            ]);
        
            return response()->json([
                'message' => 'Working day added successfully.',
                'data' => $workingDay
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validation Error',
                'errors' => $e->errors(), // Returns an array of errors for each field
            ], 422); // 422 Unprocessable Entity
        }  
    }
    public function addSubject(Request $request)
    {
        try{
            $validated = $request->validate([
                'name' => 'required|string',
                'student_number' => 'required|integer',
                'year' => 'required|integer|min:1|max:5',
                'specialties' => 'array', // فقط عند السنة الخامسة
            ]);

            $subject = Subject::create([
                'name' => $validated['name'],
                'student_number' => $validated['student_number'],
                'year' => $validated['year'],
            ]);

            if ($subject->year == 5 && isset($validated['specialties'])) {
                $subject->specialties()->sync($validated['specialties']);
            }

            return response()->json(['message' => 'Subject added', 'subject' => $subject]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validation Error',
                'errors' => $e->errors(), // Returns an array of errors for each field
            ], 422); // 422 Unprocessable Entity
        }
    }
    
    
    public function updateSubject(Request $request, $id)
    {
        try {
            $validated = $request->validate([
                'name' => 'required|string',
                'student_number' => 'required|integer',
                'year' => 'required|integer|min:1|max:5',
                'specialties' => 'array', // IDs of specialties
            ]);

            $subject = Subject::findOrFail($id);

            $subject->update([
                'name' => $validated['name'],
                'student_number' => $validated['student_number'],
                'year' => $validated['year'],
            ]);

            if ($subject->year == 5 && isset($validated['specialties'])) {
                $subject->specialties()->sync($validated['specialties']);
            } else {
                $subject->specialties()->detach(); // إزالة الربط السابق إذا لم تعد السنة الخامسة
            }

            // تحميل التخصصات المرتبطة بالمادة
            $subject->load('specialties'); // يفترض أن لديك علاقة specialties معرفة في موديل Subject

            return response()->json([
                'message' => 'Subject updated successfully',
                'subject' => $subject,
            ]);

        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validation Error',
                'errors' => $e->errors(),
            ], 422);
        }
    }
    public function addspecialties(Request $request)
    {
        try{
            $validated = $request->validate([
                'name' => 'required|string|max:255', // مثال: '09:00 AM - 11:00 AM'
            ]);

            $examTime = Specialty::create($validated);

            return response()->json([
                'message' => 'specialty added successfully.',
                'specialty' => $examTime
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validation Error',
                'errors' => $e->errors(), // Returns an array of errors for each field
            ], 422); // 422 Unprocessable Entity
        }  
    }
        
    public function dash1()
    {
        $specialties = Specialty::select('id', 'name')->get();
        $workingdays = WorkingDay::select('id', 'day')->get();

        return response()->json([
            'status' => true,
            'specialties' => $specialties,
            'workingdays'=>$workingdays
        ]);
    }
    public function updateSpecialty(Request $request, $id)
    {
        try{
            $request->validate([
                'name' => 'required|string|max:255',
            ]);
        
            $specialty = Specialty::findOrFail($id);
            $specialty->name = $request->name;
            $specialty->save();
        
            return response()->json([
                'message' => 'تم تعديل التخصص بنجاح',
                'data' => $specialty,
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validation Error',
                'errors' => $e->errors(), // Returns an array of errors for each field
            ], 422); // 422 Unprocessable Entity
        }  
    }
        
    public function updateWorkingDay(Request $request, $id)
    {
        try{
            $request->validate([
                'day' => 'required|string|in:Saturday,Sunday,Monday,Tuesday,Wednesday,Thursday,Friday',
            ]);

            $day = WorkingDay::findOrFail($id);
            $day->day = $request->day;
            $day->save();

            return response()->json([
                'message' => 'تم تعديل يوم العمل بنجاح',
                'data' => $day,
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validation Error',
                'errors' => $e->errors(), // Returns an array of errors for each field
            ], 422); // 422 Unprocessable Entity
        }  
    }   
    public function addHallWithCameras(Request $request)
    {
        try{

        $request->validate([
            'location' => 'required|string',
            'chair_number' => 'required|integer|min:1',
            'camera_addresses' => 'required|array|min:1',
            'camera_addresses.*' => 'required|string'
        ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validation Error',
                'errors' => $e->errors(), // Returns an array of errors for each field
            ], 422); // 422 Unprocessable Entity
        }  
        DB::beginTransaction();

        try {
            // إنشاء القاعة
            $hall = Hall::create([
                'location' => $request->location,
                'chair_number' => $request->chair_number,
            ]);

            // إضافة الكاميرات
            foreach ($request->camera_addresses as $address) {
                Camera::create([
                    'hall_id' => $hall->id,
                    'address' => $address,
                ]);
            }

            DB::commit();

            return response()->json([
                'status' => true,
                'message' => 'تم إنشاء القاعة والكاميرات بنجاح.',
                'hall_id' => $hall->id,
            ]);

        } catch (\Exception $e) {
            DB::rollBack();

            return response()->json([
                'status' => false,
                'message' => 'حدث خطأ أثناء الحفظ.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

        
    public function updateHallWithCameras(Request $request, $hallId)
    {
        try {
            $request->validate([
                'location' => 'required|string',
                'chair_number' => 'required|integer|min:1',
                'camera_addresses' => 'required|array|min:1',
                'camera_addresses.*' => 'required|string',
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validation Error',
                'errors' => $e->errors(),
            ], 422);
        }

        DB::beginTransaction();

        try {
            $hall = Hall::findOrFail($hallId);

            // تحديث بيانات القاعة
            $hall->update([
                'location' => $request->location,
                'chair_number' => $request->chair_number,
            ]);

            // حذف الكاميرات القديمة
            $hall->cameras()->delete();

            // إضافة الكاميرات الجديدة
            foreach ($request->camera_addresses as $address) {
                Camera::create([
                    'hall_id' => $hall->id,
                    'address' => $address,
                ]);
            }

            DB::commit();

            return response()->json([
                'status' => true,
                'message' => 'تم تعديل القاعة والكاميرات بنجاح.',
                'hall_id' => $hall->id,
            ]);

        } catch (\Exception $e) {
            DB::rollBack();

            return response()->json([
                'status' => false,
                'message' => 'حدث خطأ أثناء التعديل.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
    
    public function addSupervisorWithDays(Request $request)
    {
        try {
            $request->validate([
                'name' => 'required|string',
                'email' => 'required|email|unique:users',
                'password' => 'required|string|min:6',
                'day_ids' => 'required|array|min:1',
                'day_ids.*' => 'exists:working_days,id'
            ]);
        }catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validation Error',
                'errors' => $e->errors(), // Returns an array of errors for each field
            ], 422); // 422 Unprocessable Entity
        }

        DB::beginTransaction();

        try {
            // إنشاء المستخدم (مراقب)
            $user = User::create([
                'name' => $request->name,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'role_id' => 2
            ]);

            // ربط الأيام
            foreach ($request->day_ids as $dayId) {
                WorkingDaysForUser::create([
                    'user_id' => $user->id,
                    'day_id' => $dayId,
                ]);
            }

            DB::commit();

            // جلب تفاصيل الأيام
            $days = WorkingDay::whereIn('id', $request->day_ids)->get(['id', 'day']);

            return response()->json([
                'status' => true,
                'message' => 'تم إضافة المراقب وربطه بأيام الدوام بنجاح.',
                'user_id' => $user->id,
                'user_name' => $user->name,
                'working_days' => $days
            ]);
        } catch (\Exception $e) {
            DB::rollBack();

            return response()->json([
                'status' => false,
                'message' => 'حدث خطأ أثناء الإضافة.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
    
    public function updateSupervisorWithDays(Request $request, $userId)
    {
        try {
            $request->validate([
                'name' => 'required|string',
                'email' => "required|email|unique:users,email,$userId",
                'password' => 'nullable|string|min:6',
                'day_ids' => 'required|array|min:1',
                'day_ids.*' => 'exists:working_days,id'
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'message' => 'Validation Error',
                'errors' => $e->errors(),
            ], 422);
        }
    
        DB::beginTransaction();
    
        try {
            $user = User::findOrFail($userId);
    
            // التحقق من أنه ليس أدمن
            if ($user->role_id == 1) {
                return response()->json([
                    'status' => false,
                    'message' => 'لا يمكن تعديل بيانات الأدمن.',
                ], 403); // Forbidden
            }
    
            // تحديث بيانات المستخدم
            $user->name = $request->name;
            $user->email = $request->email;
            if ($request->filled('password')) {
                $user->password = Hash::make($request->password);
            }
            $user->save();
    
            // تحديث أيام الدوام
            WorkingDaysForUser::where('user_id', $user->id)->delete();
    
            foreach ($request->day_ids as $dayId) {
                WorkingDaysForUser::create([
                    'user_id' => $user->id,
                    'day_id' => $dayId,
                ]);
            }
    
            DB::commit();
    
            $days = WorkingDay::whereIn('id', $request->day_ids)->get(['id', 'day']);
    
            return response()->json([
                'status' => true,
                'message' => 'تم تعديل بيانات المراقب وأيام دوامه بنجاح.',
                'user_id' => $user->id,
                'user_name' => $user->name,
                'working_days' => $days
            ]);
    
        } catch (\Exception $e) {
            DB::rollBack();
    
            return response()->json([
                'status' => false,
                'message' => 'حدث خطأ أثناء التعديل.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
        
    public function dash2()
    {
        $subjects = Subject::with(['specialties:id,name'])->get();

        $halls = Hall::with(['cameras:id,hall_id,address'])->get();
        $examDays = ExamDay::select('id', 'day', 'date')->orderBy('date')->get();
        $examTimes = ExamTime::select('id', 'time')->orderBy('time')->get();
        $specialties = Specialty::select('id', 'name')->get();

        return response()->json([
            'status' => true,
            'subjects' => $subjects,
            'halls'=>$halls,
            'examDays'=>$examDays,
            'examTimes'=>$examTimes,
            'specialties'=>$specialties,
        ]);
    }
    public function showusers()
    {
        $supervisors = User::where('role_id', 2) // ۲ يرمز للمراقب
        ->with(['workingDays:id,day'])
        ->get(['id', 'name', 'email','status']);
        $workingdays = WorkingDay::select('id', 'day')->get();

        return response()->json([
            'status' => true,
            'supervisors'=>$supervisors,
            'workingdays'=>$workingdays,
        ]);
    }
    public function deleteWorkingDay($id)
    {
        $day = WorkingDay::find($id);

        if (!$day) {
            return response()->json(['message' => 'Working day not found.'], 404);
        }

        $day->delete();

        return response()->json(['message' => 'Working day deleted successfully.']);
    }
    public function deleteSpecialty($id)
    {
        $specialty = Specialty::find($id);

        if (!$specialty) {
            return response()->json(['message' => 'Specialty not found.'], 404);
        }

        $specialty->delete();

        return response()->json(['message' => 'Specialty deleted successfully.']);
    }
    public function deleteSubject($id)
    {
        $subject = Subject::find($id);
    
        if (!$subject) {
            return response()->json(['message' => 'Subject not found.'], 404);
        }
    
        $subject->delete();
    
        return response()->json(['message' => 'Subject deleted successfully.']);
    }
    public function deleteHall($id)
    {
        $hall = Hall::find($id);
    
        if (!$hall) {
            return response()->json(['message' => 'Hall not found.'], 404);
        }
    
        $hall->delete();
    
        return response()->json(['message' => 'Hall deleted successfully.']);
    }
    public function deleteExamDay($id)
    {
        $examDay = ExamDay::find($id);
    
        if (!$examDay) {
            return response()->json(['message' => 'Exam day not found.'], 404);
        }
    
        $examDay->delete();
    
        return response()->json(['message' => 'Exam day deleted successfully.']);
    }
    public function deleteExamTime($id)
    {
        $examTime = ExamTime::find($id);
    
        if (!$examTime) {
            return response()->json(['message' => 'Exam time not found.'], 404);
        }
    
        $examTime->delete();
    
        return response()->json(['message' => 'Exam time deleted successfully.']);
    }
    public function deleteSupervisor($id)
    {
        $user = User::where('role_id', 2)->find($id); // تأكد من أنه مراقب
    
        if (!$user) {
            return response()->json(['message' => 'Supervisor not found.'], 404);
        }
    
        DB::beginTransaction();
    
        try {
            // حذف علاقته بأيام الدوام من الجدول الوسيط
            $user->workingDays()->detach();
    
            // حذف المستخدم نفسه (حذف ناعم إذا كان مفعلًا)
            $user->delete();
    
            DB::commit();
    
            return response()->json([
                'status' => true,
                'message' => 'تم حذف المراقب وأيام دوامه بنجاح.',
            ]);
    
        } catch (\Exception $e) {
            DB::rollBack();
    
            return response()->json([
                'status' => false,
                'message' => 'حدث خطأ أثناء الحذف.',
                'error' => $e->getMessage()
            ], 500);
        }
    }
              

}
