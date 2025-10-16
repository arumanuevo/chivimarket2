<?php
namespace App\Policies;
use App\Models\User;
use App\Models\Business;

class BusinessPolicy
{
    public function update(User $user, Business $business): bool
    {
        \Log::info('Checking update permission', [
            'user_id' => $user->id,
            'business_user_id' => $business->user_id,
            'user_id_type' => gettype($user->id),
            'business_user_id_type' => gettype($business->user_id)
        ]);
        return $user->id === $business->user_id;
    }

    public function view(User $user, Business $business): bool
    {
        return $user->id === $business->user_id;
    }
}
