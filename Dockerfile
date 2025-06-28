# Stage 1: Build the application
# Use a specific Node.js version for reproducibility
FROM node:22-alpine AS builder

# Set the working directory
WORKDIR /usr/src/app

# Copy package.json and yarn.lock to leverage Docker cache
COPY package.json yarn.lock ./

# Install all dependencies, including devDependencies needed for the build
RUN yarn install --frozen-lockfile --production=false

# Copy the rest of the application source code
COPY . .

# Build the application
RUN yarn build

# Stage 2: Create the final production image
# Use the same base image for consistency
FROM node:22-alpine

# Set the working directory
WORKDIR /usr/src/app

# Copy package.json and yarn.lock again
COPY package.json yarn.lock ./

# Install only production dependencies
RUN yarn install --frozen-lockfile --production=true

# Copy the built application from the builder stage
COPY --from=builder /usr/src/app/dist ./dist

# The default NestJS port is 3000
EXPOSE 3000

# The command to run the application
CMD ["node", "dist/main.js"] 