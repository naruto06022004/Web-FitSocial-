<?php

use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\FriendController;
use App\Http\Controllers\Api\GymController;
use App\Http\Controllers\Api\PostController;
use App\Http\Controllers\Api\AdminUserController;
use App\Http\Controllers\Api\AdminRoleController;
use App\Http\Controllers\Api\TrainingSpaceController;

Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/register', [AuthController::class, 'register']);

Route::get('/gyms', [GymController::class, 'index']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::put('/me', [AuthController::class, 'updateMe']);

    Route::apiResource('posts', PostController::class);

    Route::get('/friends', [FriendController::class, 'index']);

    Route::get('/training-space/peers', [TrainingSpaceController::class, 'peers']);

    Route::get('/chat/conversations', [ChatController::class, 'conversations']);
    Route::get('/chat/directory', [ChatController::class, 'directory']);
    Route::get('/chat/messages', [ChatController::class, 'messages']);
    Route::post('/chat/messages', [ChatController::class, 'store']);
    Route::put('/chat/seen/{user}', [ChatController::class, 'markSeen']);

    Route::prefix('admin')->group(function () {
        Route::middleware(['ensure.admin', 'permission:users_manage'])->group(function () {
            Route::get('/users', [AdminUserController::class, 'index']);
            Route::get('/users/{user}', [AdminUserController::class, 'show']);
            Route::post('/users', [AdminUserController::class, 'store']);
            Route::put('/users/{user}', [AdminUserController::class, 'update']);
            Route::delete('/users/{user}', [AdminUserController::class, 'destroy']);
        });

        Route::middleware(['ensure.admin', 'permission:roles_manage'])->group(function () {
            Route::get('/roles', [AdminRoleController::class, 'index']);
            Route::post('/roles', [AdminRoleController::class, 'store']);
            Route::put('/roles/{role}', [AdminRoleController::class, 'update']);
            Route::delete('/roles/{role}', [AdminRoleController::class, 'destroy']);
        });
    });
});

