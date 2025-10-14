<?php
namespace App\Policies;
use App\Models\User;
use App\Models\Business;

class BusinessPolicy
{
    public function update(User $user, Business $business): bool
    {
        return $user->id === $business->user_id;
    }

    public function view(User $user, Business $business): bool
    {
        return $user->id === $business->user_id;
    }
}
