# Stage 1 - install dependencies
FROM node:16.13-alpine3.15 AS dependencies

RUN apk add --no-cache libc6-compat=1.2.2-r7
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# --------------------------------------------------------------------------------------------
# Stage 2 - builder
FROM node:16.13-alpine3.15 AS builder

ARG NEXT_PUBLIC_IS_PROD

WORKDIR /app
COPY . .
COPY --from=dependencies /app/node_modules ./node_modules
RUN yarn build
RUN yarn install --production --ignore-scripts --prefer-offline

# --------------------------------------------------------------------------------------------
# Stage 3 - the final image
FROM node:16.13-alpine3.15 AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup -g 1001 -S some-group
RUN adduser -S some-user -u 1001

COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public
COPY --from=builder --chown=some-user:some-group /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

USER some-user

EXPOSE 8080

CMD ["yarn", "start"]
