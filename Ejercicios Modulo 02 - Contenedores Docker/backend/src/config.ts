if (process.env.NODE_ENV === 'development') {
    require('dotenv').config;
}

export default {
    database: {
        url: process.env.DATABASE_URL || 'mongodb://some-mongo:27017',
        name: process.env.DATABASE_NAME || 'TopicstoreDb'
    },
    app: {
        host: process.env.HOST || 'topics-api',
        port: +process.env.PORT || 5000
    }
}