<?php

namespace App\Http\Controllers;

use App\Models\Order;
use Illuminate\Http\Request;
use App\Models\User;

class OrderController extends Controller
{
    // 🔹 CREATE ORDER
    public function store(Request $request)
    {
        $request->validate([
            'package_id' => 'required',
            'latitude' => 'required',
            'longitude' => 'required',
            'booking_date' => 'required|date'
        ]);

        // ambil user dari token
        $token = $request->header('Authorization');
        $user = User::where('api_token', $token)->first();

        if (!$user) {
            return response()->json(['message' => 'User tidak ditemukan'], 401);
        }

        $order = Order::create([
            'user_id' => $user->id,
            'package_id' => $request->package_id,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'booking_date' => $request->booking_date,
            'status' => 'pending'
        ]);

        return response()->json([
            'message' => 'Order berhasil dibuat',
            'data' => $order
        ]);
    }

    // 🔹 LIHAT ORDER USER
    public function myOrders(Request $request)
    {
        $token = $request->header('Authorization');
        $user = User::where('api_token', $token)->first();

        if (!$user) {
            return response()->json(['message' => 'User tidak ditemukan'], 401);
        }

        $orders = Order::where('user_id', $user->id)->get();

        return response()->json($orders);
    }
}