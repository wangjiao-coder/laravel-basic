<?php

namespace App\Providers;

use Aws\S3\S3Client;
use League\Flysystem\AwsS3v3\AwsS3Adapter;
use League\Flysystem\Filesystem;
use League\Flysystem\Config;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     *
     * @return void
     */
    public function register()
    {
        //
    }

    /**
     * Bootstrap any application services.
     *
     * @return void
     */
    public function boot()
    {
        $this->registerMinioDriver();
    }

    /**
     * Register minio driver
     */
    protected function registerMinioDriver()
    {
        Storage::extend('minio', function ($app, $config) {
            $client = S3Client::factory([
                'credentials' => [
                    'key' => $config["key"],
                    'secret' => $config["secret"]
                ],
                'region' => $config["region"],
                'version' => "latest",
                'bucket_endpoint' => false,
                'use_path_style_endpoint' => true,
                'endpoint' => $config["endpoint"],
            ]);
            $options = [
                'override_visibility_on_copy' => true
            ];
            return new Filesystem(
                new AwsS3Adapter($client, $config["bucket"], '', $options),
                new Config($config)
            );
        });
    }
}
