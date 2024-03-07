gcloud auth activate-service-account \
    --key-file=${SERVICE_ACCOUNT_KEY_PATH} \
    --project=${PROJECT_NAME}

echo "Packaging code and dependencies..."
mkdir ./dist
cp ./src/main/main.py ./dist
cp ./src/config/${DATA_STAGE}.toml ./dist
cp ./src/config/default.toml ./dist
cp -r ./src/quind_data_library ./dist \
    && cd ./dist \
    && zip -r quind_data_library.zip quind_data_library \
    && rm -rf quind_data_library \
    && cd ..
cp -r ./src/flows ./dist \
    && cd ./dist \
    && zip -r flows.zip flows \
    && rm -rf flows \
    && cd ..
cd ./dist \
    && rm -rf libs \
    && cd ..
gsutil -m cp -r ./dist gs://${BUCKET_NAME}/${TARGET}/
rm -rf dist
echo "Code and dependencies have been packaged successfully"