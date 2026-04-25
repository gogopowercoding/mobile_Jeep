<?php

namespace App\Http\Controllers;

use App\Models\Package;
use Illuminate\Http\Request;

class PackageController extends Controller
{
    // ambil semua data
    public function index()
    {
        return Package::all();
    }

    // tambah data
   public function store(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'description' => 'required',
            'price' => 'required|numeric',
            'duration' => 'required'
        ]);

        $package = Package::create($request->all());

        return response()->json([
            'message' => 'Data berhasil ditambahkan',
            'data' => $package
        ]);
    }
}