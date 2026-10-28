<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('community_posts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->enum('type', ['barter', 'sale', 'both'])->default('both');
            $table->string('title', 150);
            $table->text('description');
            $table->decimal('price', 10, 2)->nullable();
            $table->text('barter_for')->nullable();
            $table->string('condition', 50)->default('buen_estado');
            $table->string('contact_phone', 50)->nullable();
            $table->string('contact_whatsapp', 50);
            $table->string('contact_name', 100)->nullable();
            $table->string('city', 100)->default('Chivilcoy');
            $table->string('zone', 100)->nullable();
            $table->text('image_url')->nullable();
            $table->json('images')->nullable();
            $table->boolean('is_active')->default(true);
            $table->integer('views_count')->default(0);
            $table->boolean('accepted_terms')->default(true);
            $table->timestamp('accepted_terms_at')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->integer('reports_count')->default(0);
            $table->timestamps();

            $table->index('type');
            $table->index('is_active');
        });

        Schema::create('community_post_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('community_post_id')->constrained('community_posts')->onDelete('cascade');
            $table->foreignId('reporter_user_id')->nullable()->constrained('users')->onDelete('set null');
            $table->string('reason', 100);
            $table->text('details')->nullable();
            $table->string('reporter_ip', 45)->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('community_post_reports');
        Schema::dropIfExists('community_posts');
    }
};
