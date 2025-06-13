<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminController;


/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/


Route::post('loginAdmin', [AdminController::class, 'login']);
Route::middleware(['auth:sanctum', 'role:Admin'])->group(function () {
    Route::get('logoutAdmin', [AdminController::class, 'logout']);
    Route::get('showprofile', [AdminController::class, 'showprofile']);
    Route::post('/updateprofile', [AdminController::class, 'updateProfile']);

    Route::post('/addWorkingDay', [AdminController::class, 'addWorkingDay']);
    Route::put('/working-days/{id}', [AdminController::class, 'updateWorkingDay']);
    Route::delete('/working-days/{id}', [AdminController::class, 'deleteWorkingDay']);

    Route::post('/addspecialties', [AdminController::class, 'addspecialties']);
    Route::put('/specialties/{id}', [AdminController::class, 'updateSpecialty']);
    Route::delete('/specialties/{id}', [AdminController::class, 'deleteSpecialty']);

    Route::get('/dash1', [AdminController::class, 'dash1']);

    Route::post('/subjects', [AdminController::class, 'addSubject']);
    Route::put('/subjects/{id}', [AdminController::class, 'updateSubject']);
    Route::delete('/subjects/{id}', [AdminController::class, 'deleteSubject']);

    Route::post('/exam-days', [AdminController::class, 'addExamDay']);
    Route::put('/exam-days/{id}', [AdminController::class, 'updateExamDay']);
    Route::delete('/exam-days/{id}', [AdminController::class, 'deleteExamDay']);

    Route::post('/exam-times', [AdminController::class, 'addExamTime']);
    Route::put('/exam-times/{id}', [AdminController::class, 'updateExamTime']);
    Route::delete('/exam-times/{id}', [AdminController::class, 'deleteExamTime']);

    Route::post('/halls', [AdminController::class, 'addHallWithCameras']);
    Route::put('/halls/{id}', [AdminController::class, 'updateHallWithCameras']);
    Route::delete('/halls/{id}', [AdminController::class, 'deleteHall']);

    Route::get('/dash2', [AdminController::class, 'dash2']);

    Route::post('/supervisors', [AdminController::class, 'addSupervisorWithDays']);
    Route::put('/supervisors/{id}', [AdminController::class, 'updateSupervisorWithDays']);
    Route::delete('/supervisors/{id}', [AdminController::class, 'deleteSupervisor']);

    Route::get('/showusers', [AdminController::class, 'showusers']);

});

// Halls

// Exam Days

// Exam Times

Route::middleware(['auth:sanctum', 'role:Supervisor'])->group(function () {
    Route::get('/supervisor/tasks', [SupervisorController::class, 'index']);
});
